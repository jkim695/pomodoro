import Foundation
import FamilyControls

/// Represents a day of the week for schedule configuration
enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    /// Short display name (e.g., "S", "M", "T")
    var shortName: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    /// Full display name
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    /// All weekdays (Monday-Friday)
    static var weekdays: Set<Weekday> {
        [.monday, .tuesday, .wednesday, .thursday, .friday]
    }

    /// Weekend days (Saturday-Sunday)
    static var weekend: Set<Weekday> {
        [.saturday, .sunday]
    }

    /// All days
    static var allDays: Set<Weekday> {
        Set(Weekday.allCases)
    }
}

/// Configuration for time-based app blocking
struct TimeSchedule: Identifiable, Codable {
    let id: UUID
    var name: String
    var selection: FamilyActivitySelection
    var startHour: Int      // 0-23
    var startMinute: Int    // 0-59
    var endHour: Int        // 0-23
    var endMinute: Int      // 0-59
    var activeDays: Set<Weekday>
    var isEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "New Schedule",
        selection: FamilyActivitySelection = FamilyActivitySelection(),
        startHour: Int = 21,
        startMinute: Int = 0,
        endHour: Int = 7,
        endMinute: Int = 0,
        activeDays: Set<Weekday> = Weekday.allDays,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.selection = selection
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.activeDays = activeDays
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    /// Start time as DateComponents
    var startTimeComponents: DateComponents {
        DateComponents(hour: startHour, minute: startMinute)
    }

    /// End time as DateComponents
    var endTimeComponents: DateComponents {
        DateComponents(hour: endHour, minute: endMinute)
    }

    /// Formatted time range string (e.g., "9:00 PM - 7:00 AM")
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let calendar = Calendar.current
        let startDate = calendar.date(from: startTimeComponents) ?? Date()
        let endDate = calendar.date(from: endTimeComponents) ?? Date()

        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    /// Whether the schedule spans overnight (crosses midnight)
    var isOvernight: Bool {
        if startHour > endHour {
            return true
        } else if startHour == endHour {
            return startMinute > endMinute
        }
        return false
    }

    /// Summary of active days (e.g., "Weekdays", "Every day", "Mon, Wed, Fri")
    var activeDaysSummary: String {
        if activeDays == Weekday.allDays {
            return "Every day"
        } else if activeDays == Weekday.weekdays {
            return "Weekdays"
        } else if activeDays == Weekday.weekend {
            return "Weekends"
        } else {
            let sortedDays = activeDays.sorted { $0.rawValue < $1.rawValue }
            return sortedDays.map { $0.shortName }.joined(separator: ", ")
        }
    }

    /// Whether any apps or categories are selected
    var hasSelection: Bool {
        !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }

    /// Number of apps/categories selected
    var selectionCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count
    }
}
