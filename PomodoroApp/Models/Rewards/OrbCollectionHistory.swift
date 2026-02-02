import Foundation

/// Represents a single orb collected from completing a focus session
struct CollectedOrb: Codable, Equatable, Identifiable {
    let id: UUID
    let orbStyleId: String
    let collectedAt: Date

    init(orbStyleId: String) {
        self.id = UUID()
        self.orbStyleId = orbStyleId
        self.collectedAt = Date()
    }
}

/// Tracks all orbs collected through completed focus sessions
struct OrbCollectionHistory: Codable, Equatable {
    /// All orbs collected, in chronological order
    var collectedOrbs: [CollectedOrb] = []

    /// Total number of orbs collected
    var totalCollected: Int {
        collectedOrbs.count
    }

    /// Record a new orb collection (called when session completes)
    mutating func recordCollection(orbStyleId: String) {
        collectedOrbs.append(CollectedOrb(orbStyleId: orbStyleId))
    }

    /// Get collection count for a specific orb type
    func count(for orbStyleId: String) -> Int {
        collectedOrbs.filter { $0.orbStyleId == orbStyleId }.count
    }

    /// Get all orb style IDs for rendering (maintains collection order)
    var allOrbStyleIds: [String] {
        collectedOrbs.map { $0.orbStyleId }
    }

    /// Get unique orb types that have been collected
    var uniqueOrbTypes: Set<String> {
        Set(collectedOrbs.map { $0.orbStyleId })
    }

    /// Get collection breakdown by orb type, sorted by count descending
    func collectionBreakdown() -> [(orbStyleId: String, count: Int)] {
        var counts: [String: Int] = [:]
        for orb in collectedOrbs {
            counts[orb.orbStyleId, default: 0] += 1
        }
        return counts.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }
}
