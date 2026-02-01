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

    /// Stardust currently held in escrow for an active session ante
    var anteInEscrow: Int = 0

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

    // MARK: - Ante/Escrow Operations

    /// Check if user can afford the ante amount
    func canAffordAnte(_ amount: Int) -> Bool {
        current >= amount
    }

    /// Hold ante in escrow (deduct from current, track separately)
    /// - Returns: true if successful, false if insufficient balance
    mutating func holdAnte(_ amount: Int) -> Bool {
        guard canAffordAnte(amount) else { return false }
        current -= amount
        anteInEscrow = amount
        lastUpdated = Date()
        return true
    }

    /// Return ante from escrow (session completed successfully)
    mutating func returnAnte() {
        current += anteInEscrow
        anteInEscrow = 0
        lastUpdated = Date()
    }

    /// Burn ante (session quit early) - ante is lost permanently
    mutating func burnAnte() {
        // Don't add back to current - it's lost
        // Don't deduct from total - it was already earned legitimately
        anteInEscrow = 0
        lastUpdated = Date()
    }
}
