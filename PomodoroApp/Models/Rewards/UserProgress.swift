import Foundation

/// Tracks overall user progress and achievements
struct UserProgress: Codable, Equatable {
    /// Total sessions completed (all time)
    var totalSessionsCompleted: Int = 0

    /// Total focus minutes (all time)
    var totalFocusMinutes: Int = 0

    /// Current consecutive day streak
    var currentStreak: Int = 0

    /// Longest streak ever achieved
    var longestStreak: Int = 0

    /// Date of last completed session
    var lastSessionDate: Date?

    /// IDs of achieved milestones
    var achievedMilestones: Set<String> = []

    /// Sessions count by duration (minutes -> count)
    var sessionsByDuration: [Int: Int] = [:]

    // MARK: - Methods

    /// Record a completed session
    mutating func recordSession(durationMinutes: Int, date: Date = Date()) {
        totalSessionsCompleted += 1
        totalFocusMinutes += durationMinutes

        // Update duration stats
        sessionsByDuration[durationMinutes, default: 0] += 1

        // Update streak
        updateStreak(for: date)

        lastSessionDate = date
    }

    /// Update streak based on session date
    private mutating func updateStreak(for date: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        guard let lastDate = lastSessionDate else {
            // First session ever
            currentStreak = 1
            longestStreak = max(longestStreak, 1)
            return
        }

        let lastDay = calendar.startOfDay(for: lastDate)
        let daysDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        switch daysDifference {
        case 0:
            // Same day, streak continues (no change needed)
            break
        case 1:
            // Next day, streak continues
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        default:
            // Gap in days, streak resets
            currentStreak = 1
        }
    }

    /// Calculate streak bonus multiplier (0.0 to 0.5)
    var streakBonusMultiplier: Double {
        // +10% per streak day, max 50%
        min(Double(currentStreak - 1) * 0.1, 0.5)
    }
}

/// Milestone achievement definition
struct Milestone: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let requirement: MilestoneRequirement
    let reward: Int  // Bonus stardust
    let iconName: String

    /// Check if milestone is achieved based on progress
    func isAchieved(by progress: UserProgress) -> Bool {
        requirement.isMet(by: progress)
    }
}

/// Requirements for milestone achievement
enum MilestoneRequirement: Codable, Equatable {
    case sessionsCompleted(count: Int)
    case focusMinutes(total: Int)
    case streak(days: Int)
    case specificDuration(minutes: Int, count: Int)

    func isMet(by progress: UserProgress) -> Bool {
        switch self {
        case .sessionsCompleted(let count):
            return progress.totalSessionsCompleted >= count
        case .focusMinutes(let total):
            return progress.totalFocusMinutes >= total
        case .streak(let days):
            return progress.longestStreak >= days
        case .specificDuration(let minutes, let count):
            return (progress.sessionsByDuration[minutes] ?? 0) >= count
        }
    }

    var progressDescription: String {
        switch self {
        case .sessionsCompleted(let count):
            return "Complete \(count) sessions"
        case .focusMinutes(let total):
            return "Focus for \(total) minutes total"
        case .streak(let days):
            return "Reach a \(days)-day streak"
        case .specificDuration(let minutes, let count):
            return "Complete \(count) \(minutes)-minute sessions"
        }
    }
}

/// Predefined milestones
enum Milestones {
    static let all: [Milestone] = [
        Milestone(
            id: "first_session",
            name: "First Focus",
            description: "Complete your first focus session",
            requirement: .sessionsCompleted(count: 1),
            reward: 10,
            iconName: "star.fill"
        ),
        Milestone(
            id: "sessions_10",
            name: "Getting Started",
            description: "Complete 10 focus sessions",
            requirement: .sessionsCompleted(count: 10),
            reward: 25,
            iconName: "flame.fill"
        ),
        Milestone(
            id: "sessions_50",
            name: "Focused Mind",
            description: "Complete 50 focus sessions",
            requirement: .sessionsCompleted(count: 50),
            reward: 75,
            iconName: "brain.head.profile"
        ),
        Milestone(
            id: "sessions_100",
            name: "Centurion",
            description: "Complete 100 focus sessions",
            requirement: .sessionsCompleted(count: 100),
            reward: 150,
            iconName: "trophy.fill"
        ),
        Milestone(
            id: "focus_hour",
            name: "Hour of Power",
            description: "Accumulate 60 minutes of focus time",
            requirement: .focusMinutes(total: 60),
            reward: 15,
            iconName: "clock.fill"
        ),
        Milestone(
            id: "focus_day",
            name: "Full Day Focus",
            description: "Accumulate 8 hours of focus time",
            requirement: .focusMinutes(total: 480),
            reward: 100,
            iconName: "sun.max.fill"
        ),
        Milestone(
            id: "streak_3",
            name: "Three's Company",
            description: "Maintain a 3-day streak",
            requirement: .streak(days: 3),
            reward: 20,
            iconName: "3.circle.fill"
        ),
        Milestone(
            id: "streak_7",
            name: "Week Warrior",
            description: "Maintain a 7-day streak",
            requirement: .streak(days: 7),
            reward: 50,
            iconName: "7.circle.fill"
        ),
        Milestone(
            id: "streak_30",
            name: "Monthly Master",
            description: "Maintain a 30-day streak",
            requirement: .streak(days: 30),
            reward: 200,
            iconName: "calendar"
        )
    ]
}
