import Foundation
import FamilyControls

/// Context for determining which feature triggered a shield
enum ShieldContext: String, Codable {
    case pomodoro
    case timeSchedule
    case usageLimit
}

/// Manages shared data between the main app and extensions using App Groups
final class SharedDataManager {
    static let shared = SharedDataManager()

    private let suiteName = "group.GMR2G7RSAM.pomodoro"

    // Pomodoro keys
    private let selectionKey = "familyActivitySelection"
    private let sessionActiveKey = "isSessionActive"
    private let sessionEndedEarlyKey = "sessionEndedEarly"

    // Limits keys
    private let schedulesKey = "timeSchedules"
    private let limitsKey = "appLimits"
    private let usageRecordsKey = "usageRecords"
    private let activeScheduleIdsKey = "activeScheduleIds"
    private let activeLimitIdsKey = "activeLimitIds"
    private let shieldContextKey = "shieldContext"
    private let activeScheduleIdKey = "activeScheduleId"
    private let activeLimitIdKey = "activeLimitId"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private init() {}

    // MARK: - Family Activity Selection

    /// Saves the user's app selection to shared storage
    /// - Parameter selection: The FamilyActivitySelection to persist
    func saveSelection(_ selection: FamilyActivitySelection) {
        guard let defaults = userDefaults else { return }

        do {
            let data = try PropertyListEncoder().encode(selection)
            defaults.set(data, forKey: selectionKey)
        } catch {
            print("Failed to save selection: \(error)")
        }
    }

    /// Loads the previously saved app selection
    /// - Returns: The saved FamilyActivitySelection, or nil if none exists
    func loadSelection() -> FamilyActivitySelection? {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: selectionKey) else {
            return nil
        }

        do {
            return try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("Failed to load selection: \(error)")
            return nil
        }
    }

    /// Clears the saved selection
    func clearSelection() {
        userDefaults?.removeObject(forKey: selectionKey)
    }

    // MARK: - Session State

    /// Whether a focus session is currently active
    var isSessionActive: Bool {
        get {
            userDefaults?.bool(forKey: sessionActiveKey) ?? false
        }
        set {
            userDefaults?.set(newValue, forKey: sessionActiveKey)
        }
    }

    /// Whether the user ended the session early via shield action
    var sessionEndedEarly: Bool {
        get {
            userDefaults?.bool(forKey: sessionEndedEarlyKey) ?? false
        }
        set {
            userDefaults?.set(newValue, forKey: sessionEndedEarlyKey)
        }
    }

    /// Resets all session-related state
    func resetSessionState() {
        isSessionActive = false
        sessionEndedEarly = false
    }

    // MARK: - Time Schedules

    /// Saves time schedules to shared storage
    func saveSchedules(_ schedules: [TimeSchedule]) {
        guard let defaults = userDefaults else { return }

        do {
            let data = try PropertyListEncoder().encode(schedules)
            defaults.set(data, forKey: schedulesKey)
        } catch {
            print("Failed to save schedules: \(error)")
        }
    }

    /// Loads saved time schedules
    func loadSchedules() -> [TimeSchedule] {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: schedulesKey) else {
            return []
        }

        do {
            return try PropertyListDecoder().decode([TimeSchedule].self, from: data)
        } catch {
            print("Failed to load schedules: \(error)")
            return []
        }
    }

    // MARK: - App Limits

    /// Saves app limits to shared storage
    func saveLimits(_ limits: [AppLimit]) {
        guard let defaults = userDefaults else { return }

        do {
            let data = try PropertyListEncoder().encode(limits)
            defaults.set(data, forKey: limitsKey)
        } catch {
            print("Failed to save limits: \(error)")
        }
    }

    /// Loads saved app limits
    func loadLimits() -> [AppLimit] {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: limitsKey) else {
            return []
        }

        do {
            return try PropertyListDecoder().decode([AppLimit].self, from: data)
        } catch {
            print("Failed to load limits: \(error)")
            return []
        }
    }

    // MARK: - Usage Records

    /// Saves usage records to shared storage
    func saveUsageRecords(_ store: UsageRecordStore) {
        guard let defaults = userDefaults else { return }

        do {
            let data = try PropertyListEncoder().encode(store)
            defaults.set(data, forKey: usageRecordsKey)
        } catch {
            print("Failed to save usage records: \(error)")
        }
    }

    /// Loads saved usage records
    func loadUsageRecords() -> UsageRecordStore {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: usageRecordsKey) else {
            return UsageRecordStore()
        }

        do {
            return try PropertyListDecoder().decode(UsageRecordStore.self, from: data)
        } catch {
            print("Failed to load usage records: \(error)")
            return UsageRecordStore()
        }
    }

    // MARK: - Active Schedule/Limit Tracking

    /// IDs of currently active (monitoring) time schedules
    var activeScheduleIds: Set<UUID> {
        get {
            guard let defaults = userDefaults,
                  let data = defaults.data(forKey: activeScheduleIdsKey) else {
                return []
            }
            do {
                let ids = try PropertyListDecoder().decode([UUID].self, from: data)
                return Set(ids)
            } catch {
                return []
            }
        }
        set {
            guard let defaults = userDefaults else { return }
            do {
                let data = try PropertyListEncoder().encode(Array(newValue))
                defaults.set(data, forKey: activeScheduleIdsKey)
            } catch {
                print("Failed to save active schedule IDs: \(error)")
            }
        }
    }

    /// IDs of currently active (monitoring) app limits
    var activeLimitIds: Set<UUID> {
        get {
            guard let defaults = userDefaults,
                  let data = defaults.data(forKey: activeLimitIdsKey) else {
                return []
            }
            do {
                let ids = try PropertyListDecoder().decode([UUID].self, from: data)
                return Set(ids)
            } catch {
                return []
            }
        }
        set {
            guard let defaults = userDefaults else { return }
            do {
                let data = try PropertyListEncoder().encode(Array(newValue))
                defaults.set(data, forKey: activeLimitIdsKey)
            } catch {
                print("Failed to save active limit IDs: \(error)")
            }
        }
    }

    // MARK: - Shield Context

    /// The current shield context (which feature triggered the shield)
    var shieldContext: ShieldContext? {
        get {
            guard let defaults = userDefaults,
                  let rawValue = defaults.string(forKey: shieldContextKey) else {
                return nil
            }
            return ShieldContext(rawValue: rawValue)
        }
        set {
            userDefaults?.set(newValue?.rawValue, forKey: shieldContextKey)
        }
    }

    /// ID of the schedule that triggered the current shield (if any)
    var activeScheduleId: UUID? {
        get {
            guard let defaults = userDefaults,
                  let uuidString = defaults.string(forKey: activeScheduleIdKey) else {
                return nil
            }
            return UUID(uuidString: uuidString)
        }
        set {
            userDefaults?.set(newValue?.uuidString, forKey: activeScheduleIdKey)
        }
    }

    /// ID of the limit that triggered the current shield (if any)
    var activeLimitId: UUID? {
        get {
            guard let defaults = userDefaults,
                  let uuidString = defaults.string(forKey: activeLimitIdKey) else {
                return nil
            }
            return UUID(uuidString: uuidString)
        }
        set {
            userDefaults?.set(newValue?.uuidString, forKey: activeLimitIdKey)
        }
    }

    /// Sets shield context for a time schedule
    func setShieldContext(forSchedule scheduleId: UUID) {
        shieldContext = .timeSchedule
        activeScheduleId = scheduleId
        activeLimitId = nil
    }

    /// Sets shield context for a usage limit
    func setShieldContext(forLimit limitId: UUID) {
        shieldContext = .usageLimit
        activeLimitId = limitId
        activeScheduleId = nil
    }

    /// Sets shield context for Pomodoro
    func setShieldContextPomodoro() {
        shieldContext = .pomodoro
        activeScheduleId = nil
        activeLimitId = nil
    }

    /// Clears the shield context
    func clearShieldContext() {
        shieldContext = nil
        activeScheduleId = nil
        activeLimitId = nil
    }

    /// Resets all limits-related state
    func resetLimitsState() {
        activeScheduleIds = []
        activeLimitIds = []
        clearShieldContext()
    }
}
