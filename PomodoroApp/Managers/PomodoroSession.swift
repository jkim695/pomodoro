import Foundation
import SwiftUI
import FamilyControls
import Combine

/// Represents the current state of the pomodoro session
enum SessionState: String, Codable {
    case idle
    case focusing
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
    @Published var state: SessionState = .idle
    @Published var selection = FamilyActivitySelection()
    @Published var error: String?
    @Published var avatarState: AvatarState = .sleeping

    @AppStorage("focusDuration") var focusDuration: Int = 25  // minutes (10-180)

    let timer = TimerManager()

    private let shieldManager = ShieldManager.shared
    private let activityScheduler = ActivityScheduler.shared
    private let sharedData = SharedDataManager.shared
    private let notifications = NotificationManager.shared

    private var timerCancellable: AnyCancellable?
    private var timerObjectWillChangeCancellable: AnyCancellable?

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
            error = "Please select at least one app or category to block"
            return
        }

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

    /// Ends the focus session and returns to idle
    func endFocusSession() {
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
        if state == .focusing {
            shieldManager.removeAllShields()
            activityScheduler.stopMonitoring()
            sharedData.isSessionActive = false
        }

        // Reset everything
        timer.reset()
        notifications.cancelAll()
        state = .idle
        avatarState = .sleeping
    }

    // MARK: - App Lifecycle

    /// Called when app becomes active to check for external session changes
    func handleAppBecameActive() {
        // Recalculate timer from background
        timer.recalculateFromBackground()

        // Check if user ended session via shield action
        if sharedData.sessionEndedEarly {
            sharedData.sessionEndedEarly = false
            sharedData.isSessionActive = false

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

        // Timer just finished
        if state == .focusing {
            endFocusSession()
        }
    }
}
