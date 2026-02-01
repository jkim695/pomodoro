import Foundation
import SwiftUI
import FamilyControls
import Combine

/// Represents the current state of the pomodoro session
enum SessionState: String, Codable {
    case idle
    case focusing
    case coolingDown  // User requested quit, waiting for confirmation
}

/// Errors that can occur when starting a session
enum SessionStartError: Equatable {
    case noAppsSelected
    case insufficientStardust
    case monitoringFailed(String)
}

/// Represents the avatar's emotional/visual state
enum AvatarState: String, Codable {
    case sleeping      // Idle - waiting for session
    case working       // Focus session active
    case celebrating   // Just completed focus session
    case disappointed  // User tried to bypass shield
}

/// Single source of truth for the pomodoro app state
/// Coordinates timer, shields, and activity monitoring
@MainActor
final class PomodoroSession: ObservableObject {
    // MARK: - Constants

    /// Duration of the cool-down period before quit is allowed (seconds)
    static let coolDownDurationSeconds: Int = 10

    // MARK: - Published State

    @Published var state: SessionState = .idle
    @Published var selection = FamilyActivitySelection()
    @Published var error: String?
    @Published var avatarState: AvatarState = .sleeping
    @Published var startError: SessionStartError?
    @Published var coolDownTimeRemaining: Int = 0

    @AppStorage("focusDuration") var focusDuration: Int = 25  // minutes (10-180)

    let timer = TimerManager()

    // MARK: - Private

    private let shieldManager = ShieldManager.shared
    private let activityScheduler = ActivityScheduler.shared
    private let sharedData = SharedDataManager.shared
    private let notifications = NotificationManager.shared

    private var timerCancellable: AnyCancellable?
    private var timerObjectWillChangeCancellable: AnyCancellable?
    private var coolDownTimer: AnyCancellable?

    init() {
        // Forward timer's objectWillChange to trigger SwiftUI updates
        timerObjectWillChangeCancellable = timer.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }

        // Observe timer completion to auto-transition states
        timerCancellable = timer.$timeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remaining in
                self?.handleTimerUpdate(timeRemaining: remaining)
            }

        // Restore selection from shared storage if available
        if let savedSelection = sharedData.loadSelection() {
            selection = savedSelection
        }
    }

    // MARK: - Session Control

    /// Starts a focus session with the current selection
    func startFocusSession() {
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
            startError = .noAppsSelected
            error = "Please select at least one app or category to block"
            return
        }

        // Check and hold Stardust ante
        guard RewardsManager.shared.holdSessionAnte() else {
            startError = .insufficientStardust
            return
        }

        startError = nil
        error = nil

        // Save selection for extensions
        sharedData.saveSelection(selection)
        sharedData.isSessionActive = true
        sharedData.sessionEndedEarly = false

        // Apply shields
        shieldManager.shieldApps(selection: selection)

        // Start device activity monitoring
        do {
            try activityScheduler.startMonitoring(
                durationMinutes: focusDuration,
                selection: selection
            )
        } catch {
            // Return ante since session failed to start
            RewardsManager.shared.returnSessionAnte()
            startError = .monitoringFailed(error.localizedDescription)
            self.error = "Failed to start monitoring: \(error.localizedDescription)"
            shieldManager.removeAllShields()
            sharedData.isSessionActive = false
            return
        }

        // Start timer
        timer.start(durationSeconds: focusDuration * 60)

        // Schedule notification
        notifications.scheduleFocusComplete(in: focusDuration * 60)

        state = .focusing
        avatarState = .working
    }

    /// Ends the focus session and returns to idle (called on natural completion)
    func endFocusSession() {
        // Check if session completed naturally (for rewards)
        let wasCompleted = timer.timeRemaining == 0

        // Cancel any active cool-down
        coolDownTimer?.cancel()
        coolDownTimer = nil
        coolDownTimeRemaining = 0

        // Remove shields
        shieldManager.removeAllShields()

        // Stop monitoring
        activityScheduler.stopMonitoring()

        // Update shared state
        sharedData.isSessionActive = false

        // Reset timer
        timer.reset()

        // Cancel focus notification
        notifications.cancelFocusNotification()

        // Handle ante and rewards based on completion status
        if wasCompleted {
            // Return ante (user completed successfully)
            RewardsManager.shared.returnSessionAnte()

            // Post notification for rewards system
            NotificationCenter.default.post(
                name: .sessionCompleted,
                object: nil,
                userInfo: ["duration": focusDuration]
            )
        }

        // Celebrate completion then return to idle
        avatarState = .celebrating
        state = .idle

        Task {
            try? await Task.sleep(for: .seconds(3))
            await MainActor.run {
                if self.avatarState == .celebrating {
                    self.avatarState = .sleeping
                }
            }
        }
    }

    /// Cancels the current session and returns to idle
    func cancelSession() {
        // Remove shields if focusing
        if state == .focusing || state == .coolingDown {
            shieldManager.removeAllShields()
            activityScheduler.stopMonitoring()
            sharedData.isSessionActive = false
        }

        // Cancel cool-down if active
        coolDownTimer?.cancel()
        coolDownTimer = nil
        coolDownTimeRemaining = 0

        // Reset everything
        timer.reset()
        notifications.cancelAll()
        state = .idle
        avatarState = .sleeping
    }

    // MARK: - Cool-Down / Quit Flow

    /// Initiates the cool-down period when user wants to quit
    func requestQuit() {
        guard state == .focusing else { return }

        // Pause the main timer (but don't reset)
        timer.pause()

        // Enter cool-down state
        state = .coolingDown
        coolDownTimeRemaining = Self.coolDownDurationSeconds

        // Start cool-down countdown
        coolDownTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.tickCoolDown()
                }
            }
    }

    /// Cancels the quit attempt and resumes the session
    func cancelQuit() {
        guard state == .coolingDown else { return }

        // Cancel cool-down timer
        coolDownTimer?.cancel()
        coolDownTimer = nil
        coolDownTimeRemaining = 0

        // Resume main timer
        timer.resume()

        // Return to focusing state
        state = .focusing
    }

    /// Confirms quit after cool-down period (burns ante)
    func confirmQuit() {
        guard state == .coolingDown, coolDownTimeRemaining == 0 else { return }

        // Cancel cool-down timer
        coolDownTimer?.cancel()
        coolDownTimer = nil

        // Burn the ante (permanently lost)
        RewardsManager.shared.burnSessionAnte()

        // Clean up session
        shieldManager.removeAllShields()
        activityScheduler.stopMonitoring()
        sharedData.isSessionActive = false

        // Reset timer
        timer.reset()
        notifications.cancelAll()

        // Show disappointed state
        state = .idle
        avatarState = .disappointed

        Task {
            try? await Task.sleep(for: .seconds(3))
            await MainActor.run {
                if self.avatarState == .disappointed {
                    self.avatarState = .sleeping
                }
            }
        }
    }

    /// Decrements the cool-down timer
    private func tickCoolDown() {
        guard coolDownTimeRemaining > 0 else { return }
        coolDownTimeRemaining -= 1
        // Note: We don't auto-quit when countdown ends - user must explicitly confirm
    }

    // MARK: - App Lifecycle

    /// Called when app becomes active to check for external session changes
    func handleAppBecameActive() {
        // Recalculate timer from background
        timer.recalculateFromBackground()

        // If in cool-down when returning from background, cancel cool-down and resume session
        if state == .coolingDown {
            cancelQuit()
        }

        // Check if user ended session via shield action
        if sharedData.sessionEndedEarly {
            sharedData.sessionEndedEarly = false
            sharedData.isSessionActive = false

            // Burn ante since user ended via shield bypass
            RewardsManager.shared.burnSessionAnte()

            // Cancel any active cool-down
            coolDownTimer?.cancel()
            coolDownTimer = nil
            coolDownTimeRemaining = 0

            // Clean up
            shieldManager.removeAllShields()
            timer.reset()
            notifications.cancelAll()
            state = .idle

            // Show disappointed avatar with auto-revert
            avatarState = .disappointed
            Task {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run {
                    if self.avatarState == .disappointed {
                        self.avatarState = .sleeping
                    }
                }
            }
        }

        // Sync state with timer
        if state == .focusing {
            if timer.timeRemaining == 0 && !timer.isRunning {
                // Timer completed while backgrounded
                endFocusSession()
            }
        }
    }

    // MARK: - Private Methods

    private func handleTimerUpdate(timeRemaining: Int) {
        guard timeRemaining == 0, !timer.isRunning else { return }

        // Timer just finished - treat as success even if in cool-down
        // (user was still in session when timer completed)
        if state == .focusing || state == .coolingDown {
            // If in cool-down, need to cancel it first
            if state == .coolingDown {
                coolDownTimer?.cancel()
                coolDownTimer = nil
                coolDownTimeRemaining = 0
                state = .focusing  // Temporarily to allow proper completion
            }
            endFocusSession()
        }
    }
}
