import Foundation

/// Static catalog of all available orb styles
enum OrbCatalog {
    /// All available orb styles in the game
    static let all: [OrbStyle] = [
        // MARK: - Starter (Free)
        OrbStyle(
            id: "orb_default",
            name: "Focus Orb",
            description: "The classic focus orb. Warm and energizing.",
            category: .starter,
            rarity: .common,
            price: 0,
            primaryColorHex: "FF6B5B",  // Coral-red (pomPrimary)
            secondaryColorHex: "FFB347", // Amber (pomAccent)
            glowColorHex: "FF6B5B",
            animationStyle: .standard
        ),
        OrbStyle(
            id: "orb_ocean",
            name: "Ocean Mist",
            description: "Calm and serene, like a misty ocean morning.",
            category: .starter,
            rarity: .common,
            price: 0,
            primaryColorHex: "4ECDC4",  // Teal
            secondaryColorHex: "45B7D1", // Sky blue
            glowColorHex: "4ECDC4",
            animationStyle: .gentle
        ),

        // MARK: - Nebulae (Uncommon-Rare)
        OrbStyle(
            id: "orb_sunset",
            name: "Sunset Glow",
            description: "Captures the warmth of a golden sunset.",
            category: .nebula,
            rarity: .uncommon,
            price: 50,
            primaryColorHex: "FF8C42",  // Orange
            secondaryColorHex: "FF6B6B", // Pink-red
            glowColorHex: "FFB347",
            animationStyle: .standard
        ),
        OrbStyle(
            id: "orb_aurora",
            name: "Aurora",
            description: "Dance of the northern lights.",
            category: .nebula,
            rarity: .uncommon,
            price: 75,
            primaryColorHex: "6BCB77",  // Green
            secondaryColorHex: "9B59B6", // Purple
            glowColorHex: "6BCB77",
            animationStyle: .shimmer
        ),
        OrbStyle(
            id: "orb_rose",
            name: "Rose Quartz",
            description: "Soft pink crystal energy for mindful focus.",
            category: .nebula,
            rarity: .rare,
            price: 100,
            primaryColorHex: "F8A5C2",  // Pink
            secondaryColorHex: "F5CDD8", // Light pink
            glowColorHex: "F8A5C2",
            animationStyle: .gentle
        ),

        // MARK: - Celestials (Rare-Epic)
        OrbStyle(
            id: "orb_crimson",
            name: "Crimson Nebula",
            description: "Deep red stellar cloud with golden dust.",
            category: .celestial,
            rarity: .rare,
            price: 150,
            primaryColorHex: "C0392B",  // Deep red
            secondaryColorHex: "F39C12", // Gold
            glowColorHex: "E74C3C",
            animationStyle: .pulse
        ),
        OrbStyle(
            id: "orb_cosmic",
            name: "Cosmic Dust",
            description: "Swirling colors of a distant galaxy.",
            category: .celestial,
            rarity: .epic,
            price: 250,
            primaryColorHex: "9B59B6",  // Purple
            secondaryColorHex: "3498DB", // Blue
            glowColorHex: "8E44AD",
            animationStyle: .shimmer
        ),
        OrbStyle(
            id: "orb_supernova",
            name: "Supernova",
            description: "Explosive stellar energy at its peak.",
            category: .celestial,
            rarity: .epic,
            price: 350,
            primaryColorHex: "FFFFFF",  // White
            secondaryColorHex: "FF6B5B", // Coral
            glowColorHex: "F39C12",      // Orange glow
            animationStyle: .energetic
        ),

        // MARK: - Legendary
        OrbStyle(
            id: "orb_void",
            name: "Void Walker",
            description: "Harness the power of the cosmic void.",
            category: .legendary,
            rarity: .legendary,
            price: 500,
            primaryColorHex: "2C3E50",  // Dark blue-gray
            secondaryColorHex: "8E44AD", // Purple
            glowColorHex: "9B59B6",
            animationStyle: .pulse
        ),
        OrbStyle(
            id: "orb_prism",
            name: "Prism",
            description: "Pure light refracted into infinite colors.",
            category: .legendary,
            rarity: .legendary,
            price: 750,
            primaryColorHex: "E91E63",  // Pink
            secondaryColorHex: "00BCD4", // Cyan
            glowColorHex: "FFFFFF",
            animationStyle: .shimmer
        )
    ]

    /// Get orb style by ID
    static func style(for id: String) -> OrbStyle? {
        all.first { $0.id == id }
    }

    /// Get the default orb style
    static var defaultStyle: OrbStyle {
        all.first { $0.id == "orb_default" }!
    }

    /// Orbs grouped by category
    static var byCategory: [OrbCategory: [OrbStyle]] {
        Dictionary(grouping: all, by: { $0.category })
    }

    /// All categories in display order
    static var sortedCategories: [OrbCategory] {
        OrbCategory.allCases.sorted { $0.sortOrder < $1.sortOrder }
    }
}
