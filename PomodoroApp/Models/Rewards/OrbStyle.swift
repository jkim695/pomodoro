import Foundation
import SwiftUI

/// Defines an orb visual style that can be purchased/unlocked
struct OrbStyle: Identifiable, Codable, Equatable {
    /// Unique identifier (e.g., "orb_default", "orb_cosmic")
    let id: String

    /// Display name (e.g., "Focus Orb", "Cosmic Dust")
    let name: String

    /// Description for shop display
    let description: String

    /// Category grouping
    let category: OrbCategory

    /// Rarity tier
    let rarity: OrbRarity

    /// Stardust cost (0 = free/starter)
    let price: Int

    /// Primary gradient color (hex)
    let primaryColorHex: String

    /// Secondary accent color (hex)
    let secondaryColorHex: String

    /// Outer glow color (hex)
    let glowColorHex: String

    /// Animation behavior
    let animationStyle: OrbAnimationStyle

    // MARK: - Color Accessors

    var primaryColor: Color {
        Color(hex: primaryColorHex)
    }

    var secondaryColor: Color {
        Color(hex: secondaryColorHex)
    }

    var glowColor: Color {
        Color(hex: glowColorHex)
    }
}

/// Orb category for shop organization
enum OrbCategory: String, Codable, CaseIterable {
    case starter = "Starter"
    case nebula = "Nebulae"
    case celestial = "Celestials"
    case legendary = "Legendary"

    var sortOrder: Int {
        switch self {
        case .starter: return 0
        case .nebula: return 1
        case .celestial: return 2
        case .legendary: return 3
        }
    }
}

/// Rarity tier for visual distinction
enum OrbRarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .common: return Color.gray
        case .uncommon: return Color.green
        case .rare: return Color.blue
        case .epic: return Color.purple
        case .legendary: return Color.orange
        }
    }

    // MARK: - Gacha Properties

    /// Number of shards needed to unlock an orb of this rarity
    var shardsToUnlock: Int {
        GachaConfig.shardsToUnlock(rarity: self)
    }

    /// Number of shards needed for each star upgrade
    var shardsPerStar: Int {
        GachaConfig.shardsPerStar(rarity: self)
    }

    /// Drop rate percentage for this rarity
    var dropRate: Double {
        GachaConfig.dropRates[self] ?? 0
    }

    /// Number of shards awarded when pulling this rarity
    var shardsPerPull: Int {
        GachaConfig.shardsPerPull(rarity: self)
    }
}

/// Animation style variants for orbs
enum OrbAnimationStyle: String, Codable, CaseIterable {
    /// Standard breathing animation (default)
    case standard

    /// Slower, calmer animation
    case gentle

    /// Faster, more energetic
    case energetic

    /// Distinct pulsing effect
    case pulse

    /// Subtle color shifting
    case shimmer

    var breathingDuration: Double {
        switch self {
        case .standard: return 3.0
        case .gentle: return 4.5
        case .energetic: return 1.5
        case .pulse: return 1.0
        case .shimmer: return 2.5
        }
    }

    var scaleAmount: CGFloat {
        switch self {
        case .standard: return 1.03
        case .gentle: return 1.02
        case .energetic: return 1.06
        case .pulse: return 1.08
        case .shimmer: return 1.03
        }
    }
}
