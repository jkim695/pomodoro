import Foundation
import FamilyControls

/// Configuration for daily app usage limits
struct AppLimit: Identifiable, Codable {
    let id: UUID
    var selection: FamilyActivitySelection
    var dailyLimitMinutes: Int
    var resetHour: Int  // Hour to reset usage (0-23), default 0 (midnight)
    var isEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        selection: FamilyActivitySelection = FamilyActivitySelection(),
        dailyLimitMinutes: Int = 30,
        resetHour: Int = 0,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.selection = selection
        self.dailyLimitMinutes = dailyLimitMinutes
        self.resetHour = resetHour
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    /// Formatted daily limit string (e.g., "30 min/day", "1 hr 30 min/day")
    var formattedLimit: String {
        if dailyLimitMinutes < 60 {
            return "\(dailyLimitMinutes) min/day"
        } else {
            let hours = dailyLimitMinutes / 60
            let minutes = dailyLimitMinutes % 60
            if minutes == 0 {
                return "\(hours) hr/day"
            } else {
                return "\(hours) hr \(minutes) min/day"
            }
        }
    }

    /// Formatted daily limit string without "/day" suffix (e.g., "30 min", "1 hr 30 min")
    var formattedLimitShort: String {
        if dailyLimitMinutes < 60 {
            return "\(dailyLimitMinutes) min"
        } else {
            let hours = dailyLimitMinutes / 60
            let minutes = dailyLimitMinutes % 60
            if minutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(minutes) min"
            }
        }
    }

    /// Daily limit as DateComponents for DeviceActivityEvent
    var limitAsDateComponents: DateComponents {
        let hours = dailyLimitMinutes / 60
        let minutes = dailyLimitMinutes % 60
        return DateComponents(hour: hours, minute: minutes)
    }

    /// Whether any apps or categories are selected
    var hasSelection: Bool {
        !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }

    /// Number of apps/categories selected
    var selectionCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count
    }

    /// Common limit presets in minutes
    static let presets: [Int] = [15, 30, 45, 60, 90, 120, 180, 240]

    /// Format minutes to display string
    static func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(mins) min"
            }
        }
    }
}
