import Foundation
import DeviceActivity
import FamilyControls

/// Schedules and manages device activity monitoring for App Limits feature
final class LimitsScheduler {
    static let shared = LimitsScheduler()

    private let center = DeviceActivityCenter()
    private let sharedData = SharedDataManager.shared
    private let shieldManager = LimitsShieldManager.shared

    private init() {}

    // MARK: - Activity Name Generation

    /// Creates a unique DeviceActivityName for a time schedule
    private func activityName(forSchedule id: UUID) -> DeviceActivityName {
        DeviceActivityName("limits.schedule.\(id.uuidString)")
    }

    /// Creates a unique DeviceActivityName for a usage limit
    private func activityName(forLimit id: UUID) -> DeviceActivityName {
        DeviceActivityName("limits.usage.\(id.uuidString)")
    }

    // MARK: - Time Schedule Monitoring

    /// Starts monitoring for a time-based schedule
    /// - Parameter schedule: The TimeSchedule to monitor
    /// - Throws: DeviceActivityCenter errors if monitoring fails to start
    func startScheduleMonitoring(_ schedule: TimeSchedule) throws {
        guard schedule.isEnabled && schedule.hasSelection else { return }

        // Save schedule for extension access
        var schedules = sharedData.loadSchedules()
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
        } else {
            schedules.append(schedule)
        }
        sharedData.saveSchedules(schedules)

        // Create the schedule with repeating daily pattern
        let deviceSchedule = DeviceActivitySchedule(
            intervalStart: schedule.startTimeComponents,
            intervalEnd: schedule.endTimeComponents,
            repeats: true
        )

        // Start monitoring
        try center.startMonitoring(
            activityName(forSchedule: schedule.id),
            during: deviceSchedule
        )

        // Track as active
        var activeIds = sharedData.activeScheduleIds
        activeIds.insert(schedule.id)
        sharedData.activeScheduleIds = activeIds

        // If we're currently within the schedule window, immediately apply shields
        // (DeviceActivity only fires intervalDidStart at the exact start time)
        if isCurrentlyWithinSchedule(schedule) {
            sharedData.setShieldContext(forSchedule: schedule.id)
            shieldManager.shieldApps(selection: schedule.selection)
        }
    }

    /// Checks if the current time falls within the schedule's active window
    /// - Parameter schedule: The schedule to check
    /// - Returns: true if current time is within the schedule's time range AND today is an active day
    private func isCurrentlyWithinSchedule(_ schedule: TimeSchedule) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Check if today is an active day
        let todayWeekday = calendar.component(.weekday, from: now)
        guard let weekday = Weekday(rawValue: todayWeekday),
              schedule.activeDays.contains(weekday) else {
            return false
        }

        // Get current time components
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeMinutes = currentHour * 60 + currentMinute

        let startTimeMinutes = schedule.startHour * 60 + schedule.startMinute
        let endTimeMinutes = schedule.endHour * 60 + schedule.endMinute

        if schedule.isOvernight {
            // Overnight schedule (e.g., 21:00 - 07:00)
            // Active if current time >= start OR current time < end
            return currentTimeMinutes >= startTimeMinutes || currentTimeMinutes < endTimeMinutes
        } else {
            // Same-day schedule (e.g., 09:00 - 17:00)
            // Active if current time >= start AND current time < end
            return currentTimeMinutes >= startTimeMinutes && currentTimeMinutes < endTimeMinutes
        }
    }

    /// Stops monitoring for a specific time schedule
    /// - Parameter scheduleId: The ID of the schedule to stop monitoring
    func stopScheduleMonitoring(scheduleId: UUID) {
        center.stopMonitoring([activityName(forSchedule: scheduleId)])

        var activeIds = sharedData.activeScheduleIds
        activeIds.remove(scheduleId)
        sharedData.activeScheduleIds = activeIds

        // If this schedule was the one applying shields, remove them
        if sharedData.activeScheduleId == scheduleId {
            shieldManager.removeAllShields()
            sharedData.clearShieldContext()
        }
    }

    /// Stops all time schedule monitoring
    func stopAllScheduleMonitoring() {
        let activeIds = sharedData.activeScheduleIds
        let activityNames = activeIds.map { activityName(forSchedule: $0) }
        center.stopMonitoring(activityNames)
        sharedData.activeScheduleIds = []
    }

    // MARK: - Usage Limit Monitoring

    /// Event name for when a usage limit is reached
    static let limitReachedEventName = DeviceActivityEvent.Name("limitReached")

    /// Starts monitoring usage for an app limit
    /// - Parameter limit: The AppLimit to monitor
    /// - Throws: DeviceActivityCenter errors if monitoring fails to start
    func startUsageMonitoring(_ limit: AppLimit) throws {
        guard limit.isEnabled && limit.hasSelection else { return }

        // Save limit for extension access
        var limits = sharedData.loadLimits()
        if let index = limits.firstIndex(where: { $0.id == limit.id }) {
            limits[index] = limit
        } else {
            limits.append(limit)
        }
        sharedData.saveLimits(limits)

        // Create daily schedule that spans 24 hours (resets at specified hour)
        // intervalStart is when monitoring begins, intervalEnd is when it ends
        // For a full day that resets at resetHour, we go from resetHour:00 to (resetHour-1):59
        let intervalStart = DateComponents(hour: limit.resetHour, minute: 0)

        // Calculate end time: 1 minute before the next reset
        // e.g., if resetHour is 0 (midnight), end at 23:59
        let endHour = (limit.resetHour + 23) % 24
        let intervalEnd = DateComponents(hour: endHour, minute: 59)

        let schedule = DeviceActivitySchedule(
            intervalStart: intervalStart,
            intervalEnd: intervalEnd,
            repeats: true
        )

        // Create threshold event
        let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
            Self.limitReachedEventName: DeviceActivityEvent(
                applications: limit.selection.applicationTokens,
                categories: limit.selection.categoryTokens,
                threshold: limit.limitAsDateComponents
            )
        ]

        // Start monitoring with events
        try center.startMonitoring(
            activityName(forLimit: limit.id),
            during: schedule,
            events: events
        )

        // Track as active
        var activeIds = sharedData.activeLimitIds
        activeIds.insert(limit.id)
        sharedData.activeLimitIds = activeIds
    }

    /// Stops monitoring usage for a specific limit
    /// - Parameter limitId: The ID of the limit to stop monitoring
    func stopUsageMonitoring(limitId: UUID) {
        center.stopMonitoring([activityName(forLimit: limitId)])

        var activeIds = sharedData.activeLimitIds
        activeIds.remove(limitId)
        sharedData.activeLimitIds = activeIds
    }

    /// Stops all usage limit monitoring
    func stopAllUsageMonitoring() {
        let activeIds = sharedData.activeLimitIds
        let activityNames = activeIds.map { activityName(forLimit: $0) }
        center.stopMonitoring(activityNames)
        sharedData.activeLimitIds = []
    }

    // MARK: - Sync All

    /// Syncs all enabled schedules and limits with DeviceActivityCenter
    /// Call this on app launch to ensure monitoring state matches saved data
    func syncAll() {
        // Stop all existing monitoring first
        stopAllScheduleMonitoring()
        stopAllUsageMonitoring()

        // Re-enable all enabled schedules
        let schedules = sharedData.loadSchedules()
        for schedule in schedules where schedule.isEnabled {
            do {
                try startScheduleMonitoring(schedule)
            } catch {
                print("Failed to start schedule monitoring for \(schedule.name): \(error)")
            }
        }

        // Re-enable all enabled limits
        let limits = sharedData.loadLimits()
        for limit in limits where limit.isEnabled {
            do {
                try startUsageMonitoring(limit)
            } catch {
                print("Failed to start usage monitoring for limit: \(error)")
            }
        }
    }

    /// Stops all monitoring (both schedules and limits)
    func stopAllMonitoring() {
        stopAllScheduleMonitoring()
        stopAllUsageMonitoring()
    }
}

/// Error types for LimitsScheduler
enum LimitsSchedulerError: LocalizedError {
    case noAppsSelected
    case invalidSchedule

    var errorDescription: String? {
        switch self {
        case .noAppsSelected:
            return "No apps or categories selected for this limit"
        case .invalidSchedule:
            return "Invalid schedule configuration"
        }
    }
}
