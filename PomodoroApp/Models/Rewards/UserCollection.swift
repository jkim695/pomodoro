import Foundation

/// Tracks what the user owns and has equipped
struct UserCollection: Codable, Equatable {
    /// IDs of owned orb styles
    var ownedOrbStyleIds: Set<String> = ["orb_default", "orb_ocean"]

    /// Currently equipped orb style ID
    var equippedOrbStyleId: String = "orb_default"

    /// Purchase history
    var purchaseHistory: [PurchaseRecord] = []

    // MARK: - Gacha Properties

    /// Shard counts for each orb
    var shardInventory: ShardInventory = ShardInventory()

    /// Star levels for owned orbs (1-5)
    var starLevels: OrbStarLevels = OrbStarLevels()

    /// Pity counter for guaranteed pulls
    var pityCounter: GachaPityCounter = GachaPityCounter()

    /// History of gacha pulls
    var pullHistory: GachaPullHistory = GachaPullHistory()

    /// History of orbs collected from completed sessions
    var orbCollectionHistory: OrbCollectionHistory = OrbCollectionHistory()

    // MARK: - Methods

    /// Check if user owns a specific orb style
    func owns(_ styleId: String) -> Bool {
        ownedOrbStyleIds.contains(styleId)
    }

    /// Check if a specific orb style is equipped
    func isEquipped(_ styleId: String) -> Bool {
        equippedOrbStyleId == styleId
    }

    /// Add a newly purchased orb style
    mutating func addPurchase(styleId: String, price: Int) {
        ownedOrbStyleIds.insert(styleId)
        purchaseHistory.append(PurchaseRecord(
            id: UUID(),
            orbStyleId: styleId,
            price: price,
            purchaseDate: Date()
        ))
    }

    /// Equip an owned orb style
    /// - Returns: true if successful, false if not owned
    mutating func equip(_ styleId: String) -> Bool {
        guard ownedOrbStyleIds.contains(styleId) else { return false }
        equippedOrbStyleId = styleId
        return true
    }

    // MARK: - Gacha Methods

    /// Get shard count for an orb
    func shardCount(for styleId: String) -> Int {
        shardInventory.count(for: styleId)
    }

    /// Get star level for an owned orb (0 if not owned)
    func starLevel(for styleId: String) -> Int {
        starLevels.level(for: styleId)
    }

    /// Progress toward unlocking (0.0 to 1.0)
    func unlockProgress(for style: OrbStyle) -> Double {
        guard !owns(style.id) else { return 1.0 }
        let current = Double(shardCount(for: style.id))
        let required = Double(style.rarity.shardsToUnlock)
        return min(current / required, 1.0)
    }

    /// Progress toward next star (0.0 to 1.0, nil if maxed or not owned)
    func upgradeProgress(for style: OrbStyle) -> Double? {
        guard owns(style.id) else { return nil }
        let currentStar = starLevel(for: style.id)
        guard currentStar < OrbStarLevels.maxStarLevel else { return nil }

        let current = Double(shardCount(for: style.id))
        let required = Double(style.rarity.shardsPerStar)
        return min(current / required, 1.0)
    }

    /// Check if orb can be unlocked with current shards
    func canUnlock(_ styleId: String) -> Bool {
        guard !owns(styleId), let style = OrbCatalog.style(for: styleId) else { return false }
        return shardCount(for: styleId) >= style.rarity.shardsToUnlock
    }

    /// Check if orb can be upgraded with current shards
    func canUpgrade(_ styleId: String) -> Bool {
        guard owns(styleId), let style = OrbCatalog.style(for: styleId) else { return false }
        guard starLevels.canUpgrade(styleId) else { return false }
        return shardCount(for: styleId) >= style.rarity.shardsPerStar
    }
}

/// Record of a purchase transaction
struct PurchaseRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let orbStyleId: String
    let price: Int
    let purchaseDate: Date
}
