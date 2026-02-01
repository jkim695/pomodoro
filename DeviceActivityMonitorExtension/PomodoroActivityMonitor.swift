import Foundation
import DeviceActivity
import ManagedSettings
import FamilyControls

/// Monitors device activity and manages shields during focus sessions and app limits
class PomodoroActivityMonitor: DeviceActivityMonitor {
    // Separate stores for different contexts
    private let pomodoroStore = ManagedSettingsStore(named: .pomodoro)
    private let limitsStore = ManagedSettingsStore(named: .limits)

    // MARK: - Activity Name Parsing

    private enum ActivityContext {
        case pomodoro
        case timeSchedule(id: UUID)
        case usageLimit(id: UUID)
    }

    private func parseActivityName(_ activityName: DeviceActivityName) -> ActivityContext {
        let name = activityName.rawValue

        if name.hasPrefix("limits.schedule.") {
            let uuidString = String(name.dropFirst("limits.schedule.".count))
            if let uuid = UUID(uuidString: uuidString) {
                return .timeSchedule(id: uuid)
            }
        } else if name.hasPrefix("limits.usage.") {
            let uuidString = String(name.dropFirst("limits.usage.".count))
            if let uuid = UUID(uuidString: uuidString) {
                return .usageLimit(id: uuid)
            }
        }

        return .pomodoro
    }

    // MARK: - Interval Start/End

    /// Called when an interval starts
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        let context = parseActivityName(activity)

        switch context {
        case .pomodoro:
            handlePomodoroStart()

        case .timeSchedule(let id):
            handleScheduleStart(scheduleId: id)

        case .usageLimit(let id):
            // New day/interval started - reset usage tracking for this limit
            handleUsageLimitIntervalStart(limitId: id)
        }
    }

    /// Called when an interval ends
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        let context = parseActivityName(activity)

        switch context {
        case .pomodoro:
            handlePomodoroEnd()

        case .timeSchedule(let id):
            handleScheduleEnd(scheduleId: id)

        case .usageLimit(let id):
            // Interval end means new day - usage will be reset by app
            // Just clear any shields that might have been applied
            handleUsageLimitReset(limitId: id)
        }
    }

    // MARK: - Event Threshold

    /// Called when a usage limit threshold is reached
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        let context = parseActivityName(activity)

        if case .usageLimit(let id) = context {
            let eventName = event.rawValue

            if eventName == "limitReached" {
                // Full limit reached - apply shields and record final usage
                handleUsageLimitReached(limitId: id)
                // Record that limit was reached
                recordUsageProgress(limitId: id, minutes: nil, limitReached: true)
            } else if eventName.hasPrefix("progress_") {
                // Progress checkpoint - update usage data in App Group
                if let minutesString = eventName.split(separator: "_").last,
                   let minutes = Int(minutesString) {
                    recordUsageProgress(limitId: id, minutes: minutes, limitReached: false)
                }
            }
        }
    }

    /// Records usage progress to App Group (Monitor extension CAN write to App Group!)
    private func recordUsageProgress(limitId: UUID, minutes: Int?, limitReached: Bool) {
        let limits = SharedDataManager.shared.loadLimits()
        guard let limit = limits.first(where: { $0.id == limitId }) else { return }

        // Determine the used seconds
        let usedSeconds: Int
        if limitReached {
            usedSeconds = limit.dailyLimitMinutes * 60
        } else if let mins = minutes {
            usedSeconds = mins * 60
        } else {
            return
        }

        // Save app usage data for the main app to read
        let usageData = AppUsageData(
            date: Calendar.current.startOfDay(for: Date()),
            totalSeconds: usedSeconds,
            lastUpdated: Date()
        )
        SharedDataManager.shared.saveAppUsageData(usageData)

        // Also update the usage record for this specific limit
        var usageRecords = SharedDataManager.shared.loadUsageRecords()
        usageRecords.records[limitId] = UsageRecord(
            limitId: limitId,
            date: Calendar.current.startOfDay(for: Date()),
            usedSeconds: usedSeconds,
            lastUpdated: Date()
        )
        SharedDataManager.shared.saveUsageRecords(usageRecords)
    }

    // MARK: - Pomodoro Handlers

    private func handlePomodoroStart() {
        guard let selection = SharedDataManager.shared.loadSelection() else {
            return
        }

        SharedDataManager.shared.setShieldContextPomodoro()
        applyShields(to: pomodoroStore, for: selection)
        SharedDataManager.shared.isSessionActive = true
    }

    private func handlePomodoroEnd() {
        removeShields(from: pomodoroStore)
        SharedDataManager.shared.isSessionActive = false
        SharedDataManager.shared.clearShieldContext()
    }

    // MARK: - Time Schedule Handlers

    private func handleScheduleStart(scheduleId: UUID) {
        let schedules = SharedDataManager.shared.loadSchedules()
        guard let schedule = schedules.first(where: { $0.id == scheduleId }),
              schedule.isEnabled else {
            return
        }

        // Check if today is an active day
        let today = Calendar.current.component(.weekday, from: Date())
        guard let weekday = Weekday(rawValue: today),
              schedule.activeDays.contains(weekday) else {
            return
        }

        SharedDataManager.shared.setShieldContext(forSchedule: scheduleId)
        applyShields(to: limitsStore, for: schedule.selection)
    }

    private func handleScheduleEnd(scheduleId: UUID) {
        // Only clear if this schedule was the active one
        if SharedDataManager.shared.activeScheduleId == scheduleId {
            removeShields(from: limitsStore)
            SharedDataManager.shared.clearShieldContext()
        }
    }

    // MARK: - Usage Limit Handlers

    /// Called when a new monitoring interval starts (new day)
    private func handleUsageLimitIntervalStart(limitId: UUID) {
        // Reset usage data for this limit at the start of a new day
        var usageRecords = SharedDataManager.shared.loadUsageRecords()
        usageRecords.records[limitId] = UsageRecord(
            limitId: limitId,
            date: Calendar.current.startOfDay(for: Date()),
            usedSeconds: 0,
            lastUpdated: Date()
        )
        SharedDataManager.shared.saveUsageRecords(usageRecords)

        // Also reset the general app usage data
        let usageData = AppUsageData(
            date: Calendar.current.startOfDay(for: Date()),
            totalSeconds: 0,
            lastUpdated: Date()
        )
        SharedDataManager.shared.saveAppUsageData(usageData)

        // Clear any shields from the previous day
        removeShields(from: limitsStore)
    }

    private func handleUsageLimitReached(limitId: UUID) {
        let limits = SharedDataManager.shared.loadLimits()
        guard let limit = limits.first(where: { $0.id == limitId }),
              limit.isEnabled else {
            return
        }

        SharedDataManager.shared.setShieldContext(forLimit: limitId)
        applyShields(to: limitsStore, for: limit.selection)
    }

    private func handleUsageLimitReset(limitId: UUID) {
        // Clear shields if this limit was the one that applied them
        if SharedDataManager.shared.activeLimitId == limitId {
            removeShields(from: limitsStore)
            SharedDataManager.shared.clearShieldContext()
        }
    }

    // MARK: - Shield Management

    private func applyShields(to store: ManagedSettingsStore, for selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil
            : selection.applicationTokens

        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)

        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
    }

    private func removeShields(from store: ManagedSettingsStore) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
    }
}

// Extension to access ManagedSettingsStore names from extensions
extension ManagedSettingsStore.Name {
    static let pomodoro = Self("pomodoro")
    static let limits = Self("limits")
}
