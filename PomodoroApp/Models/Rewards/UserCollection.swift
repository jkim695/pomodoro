import Foundation

/// Tracks what the user owns and has equipped
struct UserCollection: Codable, Equatable {
    /// IDs of owned orb styles
    var ownedOrbStyleIds: Set<String> = ["orb_default", "orb_ocean"]

    /// Currently equipped orb style ID
    var equippedOrbStyleId: String = "orb_default"

    /// Purchase history
    var purchaseHistory: [PurchaseRecord] = []

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
}

/// Record of a purchase transaction
struct PurchaseRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let orbStyleId: String
    let price: Int
    let purchaseDate: Date
}
