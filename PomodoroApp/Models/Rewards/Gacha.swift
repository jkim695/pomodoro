import Foundation

// MARK: - Shard Inventory

/// Tracks shard counts for each orb
struct ShardInventory: Codable, Equatable {
    /// orbId -> shard count
    var shards: [String: Int] = [:]

    /// Get shard count for an orb
    func count(for orbId: String) -> Int {
        shards[orbId] ?? 0
    }

    /// Add shards for an orb
    mutating func add(_ amount: Int, for orbId: String) {
        shards[orbId, default: 0] += amount
    }

    /// Consume shards for unlock/upgrade (returns false if insufficient)
    mutating func consume(_ amount: Int, for orbId: String) -> Bool {
        guard shards[orbId, default: 0] >= amount else { return false }
        shards[orbId]! -= amount
        return true
    }
}

// MARK: - Star Levels

/// Tracks star levels for owned orbs (1-5 stars)
struct OrbStarLevels: Codable, Equatable {
    /// orbId -> star level (1-5)
    var levels: [String: Int] = [:]

    /// Maximum star level an orb can reach
    static let maxStarLevel = 5

    /// Get star level (returns 0 if not owned, 1-5 if owned)
    func level(for orbId: String) -> Int {
        levels[orbId] ?? 0
    }

    /// Set initial star level when orb is unlocked
    mutating func unlock(_ orbId: String) {
        levels[orbId] = 1
    }

    /// Upgrade star level (returns new level, or nil if already max)
    mutating func upgrade(_ orbId: String) -> Int? {
        guard let current = levels[orbId], current < Self.maxStarLevel else { return nil }
        levels[orbId] = current + 1
        return current + 1
    }

    /// Check if orb can be upgraded (owned and below max)
    func canUpgrade(_ orbId: String) -> Bool {
        guard let level = levels[orbId] else { return false }
        return level < Self.maxStarLevel
    }
}

// MARK: - Gacha Pull Result

/// Result of a single gacha pull
struct GachaPullResult: Identifiable, Codable, Equatable {
    let id: UUID
    let orbId: String
    let orbName: String
    let rarity: OrbRarity
    let shardsAwarded: Int
    let wasGuaranteed: Bool
    let timestamp: Date

    init(
        orbId: String,
        orbName: String,
        rarity: OrbRarity,
        shardsAwarded: Int,
        wasGuaranteed: Bool = false
    ) {
        self.id = UUID()
        self.orbId = orbId
        self.orbName = orbName
        self.rarity = rarity
        self.shardsAwarded = shardsAwarded
        self.wasGuaranteed = wasGuaranteed
        self.timestamp = Date()
    }
}

// MARK: - Pity Counter

/// Tracks pulls since last guaranteed rarity for pity system
struct GachaPityCounter: Codable, Equatable {
    /// Pulls since last Rare or higher
    var pullsSinceRare: Int = 0

    /// Pulls since last Epic or higher
    var pullsSinceEpic: Int = 0

    /// Pulls since last Legendary
    var pullsSinceLegendary: Int = 0

    /// Total pulls all time (for stats)
    var totalPulls: Int = 0

    /// Record a pull and update counters based on rarity received
    mutating func recordPull(rarity: OrbRarity) {
        totalPulls += 1

        switch rarity {
        case .common, .uncommon:
            pullsSinceRare += 1
            pullsSinceEpic += 1
            pullsSinceLegendary += 1
        case .rare:
            pullsSinceRare = 0
            pullsSinceEpic += 1
            pullsSinceLegendary += 1
        case .epic:
            pullsSinceRare = 0
            pullsSinceEpic = 0
            pullsSinceLegendary += 1
        case .legendary:
            pullsSinceRare = 0
            pullsSinceEpic = 0
            pullsSinceLegendary = 0
        }
    }

    /// Check what guaranteed rarity should be awarded (if any)
    func guaranteedRarity() -> OrbRarity? {
        // Check in order of highest tier first
        if pullsSinceLegendary >= GachaConfig.pityLegendary - 1 {
            return .legendary
        }
        if pullsSinceEpic >= GachaConfig.pityEpic - 1 {
            return .epic
        }
        if pullsSinceRare >= GachaConfig.pityRare - 1 {
            return .rare
        }
        return nil
    }
}

// MARK: - Gacha Pull History

/// History of gacha pulls for display and analytics
struct GachaPullHistory: Codable, Equatable {
    /// All recorded pulls (most recent first)
    var pulls: [GachaPullResult] = []

    /// Maximum number of pulls to retain
    private static let maxHistorySize = 100

    /// Add a pull to history (keeps most recent entries)
    mutating func add(_ pull: GachaPullResult) {
        pulls.insert(pull, at: 0)
        if pulls.count > Self.maxHistorySize {
            pulls = Array(pulls.prefix(Self.maxHistorySize))
        }
    }

    /// Recent pulls (last 10)
    var recent: [GachaPullResult] {
        Array(pulls.prefix(10))
    }
}
