import Foundation
import Combine

/// Manages countdown timer with background recovery support
@MainActor
final class TimerManager: ObservableObject {
    @Published var timeRemaining: Int = 0      // seconds
    @Published var totalTime: Int = 0          // seconds
    @Published var isRunning: Bool = false

    /// Progress from 0.0 to 1.0 representing how much time has elapsed
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }

    private var timerSubscription: AnyCancellable?
    private var startTime: Date?
    private var pausedTimeRemaining: Int?

    private let userDefaults = UserDefaults.standard
    private let startTimeKey = "timer.startTime"
    private let totalTimeKey = "timer.totalTime"

    init() {
        restoreFromBackground()
    }

    /// Starts a new countdown timer
    /// - Parameter durationSeconds: Total duration in seconds
    func start(durationSeconds: Int) {
        totalTime = durationSeconds
        timeRemaining = durationSeconds
        startTime = Date()
        pausedTimeRemaining = nil
        isRunning = true

        saveTimerState()
        startTimerPublisher()
    }

    /// Pauses the current timer
    func pause() {
        guard isRunning else { return }

        timerSubscription?.cancel()
        timerSubscription = nil
        pausedTimeRemaining = timeRemaining
        isRunning = false

        clearSavedState()
    }

    /// Resumes the timer from paused state
    func resume() {
        guard !isRunning, let pausedTime = pausedTimeRemaining, pausedTime > 0 else { return }

        timeRemaining = pausedTime
        startTime = Date()
        pausedTimeRemaining = nil
        isRunning = true

        saveTimerState()
        startTimerPublisher()
    }

    /// Resets the timer to initial state
    func reset() {
        timerSubscription?.cancel()
        timerSubscription = nil

        timeRemaining = 0
        totalTime = 0
        isRunning = false
        startTime = nil
        pausedTimeRemaining = nil

        clearSavedState()
    }

    /// Called when app becomes active to recalculate time based on elapsed duration
    func recalculateFromBackground() {
        guard isRunning, let start = startTime else { return }

        let elapsed = Int(Date().timeIntervalSince(start))
        let newRemaining = totalTime - elapsed

        if newRemaining <= 0 {
            // Timer completed while in background
            timeRemaining = 0
            isRunning = false
            timerSubscription?.cancel()
            timerSubscription = nil
            clearSavedState()
        } else {
            timeRemaining = newRemaining
        }
    }

    // MARK: - Private Methods

    private func startTimerPublisher() {
        timerSubscription?.cancel()

        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }

                    if self.timeRemaining > 0 {
                        self.timeRemaining -= 1
                    }

                    if self.timeRemaining == 0 {
                        self.isRunning = false
                        self.timerSubscription?.cancel()
                        self.timerSubscription = nil
                        self.clearSavedState()
                    }
                }
            }
    }

    private func saveTimerState() {
        userDefaults.set(startTime, forKey: startTimeKey)
        userDefaults.set(totalTime, forKey: totalTimeKey)
    }

    private func clearSavedState() {
        userDefaults.removeObject(forKey: startTimeKey)
        userDefaults.removeObject(forKey: totalTimeKey)
    }

    private func restoreFromBackground() {
        guard let savedStartTime = userDefaults.object(forKey: startTimeKey) as? Date else {
            return
        }

        let savedTotalTime = userDefaults.integer(forKey: totalTimeKey)
        guard savedTotalTime > 0 else { return }

        let elapsed = Int(Date().timeIntervalSince(savedStartTime))
        let remaining = savedTotalTime - elapsed

        if remaining > 0 {
            totalTime = savedTotalTime
            timeRemaining = remaining
            startTime = savedStartTime
            isRunning = true
            startTimerPublisher()
        } else {
            clearSavedState()
        }
    }
}
