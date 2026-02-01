import Foundation

/// Tracks user's earned Stardust currency
struct StardustBalance: Codable, Equatable {
    /// Lifetime total Stardust earned
    var total: Int = 0

    /// Current spendable balance
    var current: Int = 0

    /// Reward from the most recent session (for display)
    var lastSessionReward: Int = 0

    /// When the balance was last updated
    var lastUpdated: Date = Date()

    /// Add earned Stardust from a completed session
    mutating func add(_ amount: Int) {
        total += amount
        current += amount
        lastSessionReward = amount
        lastUpdated = Date()
    }

    /// Spend Stardust on a purchase
    /// - Returns: true if successful, false if insufficient balance
    mutating func spend(_ amount: Int) -> Bool {
        guard current >= amount else { return false }
        current -= amount
        lastUpdated = Date()
        return true
    }
}
