import Foundation
import SwiftUI
import FamilyControls
import Combine

/// Represents the current state of the pomodoro session
enum SessionState: String, Codable {
    case idle
    case focusing
    case onBreak
}

/// Single source of truth for the pomodoro app state
/// Coordinates timer, shields, and activity monitoring
@MainActor
final class PomodoroSession: ObservableObject {
    @Published var state: SessionState = .idle
    @Published var selection = FamilyActivitySelection()
    @Published var error: String?

    @AppStorage("focusDuration") var focusDuration: Int = 25  // minutes
    @AppStorage("breakDuration") var breakDuration: Int = 5   // minutes

    let timer = TimerManager()

    private let shieldManager = ShieldManager.shared
    private let activityScheduler = ActivityScheduler.shared
    private let sharedData = SharedDataManager.shared
    private let notifications = NotificationManager.shared

    private var timerCancellable: AnyCancellable?

    init() {
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
    }

    /// Ends the focus session and optionally transitions to break
    /// - Parameter startBreak: Whether to start a break after focus ends
    func endFocusSession(startBreak: Bool = true) {
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

        if startBreak && breakDuration > 0 {
            self.startBreak()
        } else {
            state = .idle
        }
    }

    /// Starts a break period (no shields)
    func startBreak() {
        state = .onBreak
        timer.start(durationSeconds: breakDuration * 60)
        notifications.scheduleBreakComplete(in: breakDuration * 60)
    }

    /// Ends the break and returns to idle
    func endBreak() {
        timer.reset()
        notifications.cancelBreakNotification()
        state = .idle
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
        }

        // Sync state with timer
        if state == .focusing || state == .onBreak {
            if timer.timeRemaining == 0 && !timer.isRunning {
                // Timer completed while backgrounded
                if state == .focusing {
                    endFocusSession(startBreak: true)
                } else {
                    endBreak()
                }
            }
        }
    }

    // MARK: - Private Methods

    private func handleTimerUpdate(timeRemaining: Int) {
        guard timeRemaining == 0, !timer.isRunning else { return }

        // Timer just finished
        switch state {
        case .focusing:
            endFocusSession(startBreak: true)
        case .onBreak:
            endBreak()
        case .idle:
            break
        }
    }
}
