import Foundation
import DeviceActivity
import FamilyControls

/// Schedules and manages device activity monitoring for focus sessions
final class ActivityScheduler {
    static let shared = ActivityScheduler()

    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("pomodoro.focus.session")

    private init() {}

    /// Starts monitoring a focus session
    /// - Parameters:
    ///   - durationMinutes: How long the session should last in minutes
    ///   - selection: The apps/categories to shield during the session
    /// - Throws: DeviceActivityCenter errors if monitoring fails to start
    func startMonitoring(durationMinutes: Int, selection: FamilyActivitySelection) throws {
        // Save selection for extensions to access
        SharedDataManager.shared.saveSelection(selection)
        SharedDataManager.shared.isSessionActive = true
        SharedDataManager.shared.sessionEndedEarly = false

        // Calculate schedule
        let now = Date()
        let calendar = Calendar.current

        guard let startComponents = calendar.dateComponents([.hour, .minute, .second], from: now) as DateComponents?,
              let endDate = calendar.date(byAdding: .minute, value: durationMinutes, to: now),
              let endComponents = calendar.dateComponents([.hour, .minute, .second], from: endDate) as DateComponents? else {
            throw ActivitySchedulerError.invalidDateComponents
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        // Start monitoring
        try center.startMonitoring(activityName, during: schedule)
    }

    /// Stops monitoring and ends the current session
    func stopMonitoring() {
        center.stopMonitoring([activityName])
        SharedDataManager.shared.isSessionActive = false
    }

    /// Stops all device activity monitoring
    func stopAllMonitoring() {
        center.stopMonitoring()
        SharedDataManager.shared.isSessionActive = false
    }
}

enum ActivitySchedulerError: LocalizedError {
    case invalidDateComponents

    var errorDescription: String? {
        switch self {
        case .invalidDateComponents:
            return "Failed to create valid date components for the schedule"
        }
    }
}
