import Foundation

/// Configuration constants for the gacha system
enum GachaConfig {
    // MARK: - Pull Costs

    /// Cost in Stardust for a single pull
    static let singlePullCost = 15

    /// Cost in Stardust for a 10-pull (20% discount from 150)
    static let tenPullCost = 120

    // MARK: - Shards Required to Unlock

    /// Number of shards needed to unlock an orb of given rarity
    static func shardsToUnlock(rarity: OrbRarity) -> Int {
        switch rarity {
        case .common: return 10
        case .uncommon: return 25
        case .rare: return 50
        case .epic: return 100
        case .legendary: return 200
        }
    }

    // MARK: - Shards Required per Star Upgrade

    /// Number of shards needed for each star upgrade (same as unlock cost)
    static func shardsPerStar(rarity: OrbRarity) -> Int {
        shardsToUnlock(rarity: rarity)
    }

    // MARK: - Drop Rates

    /// Drop rate percentages by rarity (must sum to 100)
    static let dropRates: [OrbRarity: Double] = [
        .common: 50.0,
        .uncommon: 25.0,
        .rare: 15.0,
        .epic: 7.0,
        .legendary: 3.0
    ]

    // MARK: - Shards Awarded Per Pull

    /// Number of shards awarded when pulling an orb of given rarity
    static func shardsPerPull(rarity: OrbRarity) -> Int {
        switch rarity {
        case .common: return 3
        case .uncommon: return 5
        case .rare: return 10
        case .epic: return 20
        case .legendary: return 40
        }
    }

    // MARK: - Pity Thresholds

    /// Guaranteed Rare or better every N pulls
    static let pityRare = 30

    /// Guaranteed Epic or better every N pulls
    static let pityEpic = 50

    /// Guaranteed Legendary every N pulls
    static let pityLegendary = 100
}
