import SwiftUI
import UIKit

extension Color {
    // MARK: - Adaptive Backgrounds
    static let pomBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "121212")   // Dark gray
            : UIColor(hex: "FAFAFA")   // Clean off-white
    })

    static let pomCardBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "1E1E1E")   // Elevated dark
            : UIColor(hex: "FFFFFF")   // Pure white
    })

    static let pomCardBackgroundAlt = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "2A2A2A")   // Slightly lighter dark
            : UIColor(hex: "F5F5F7")   // Subtle gray
    })

    // MARK: - Primary Actions (Focus state)
    static let pomPrimary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "FF7B6B")   // Slightly brighter coral for dark mode
            : UIColor(hex: "FF6B5B")   // Vibrant coral-red
    })

    static let pomPrimaryDark = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "FF6B5B")   // Original coral
            : UIColor(hex: "E55A4A")   // Pressed state
    })

    static let pomPrimaryLight = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "3D2A28")   // Dark coral tint
            : UIColor(hex: "FFE8E5")   // Light coral
    })

    // MARK: - Secondary (Break state)
    static let pomSecondary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "7BD987")   // Brighter green for dark mode
            : UIColor(hex: "6BCB77")   // Fresh green
    })

    static let pomSecondaryLight = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "1E3D22")   // Dark green tint
            : UIColor(hex: "E8F8EA")   // Light green
    })

    // MARK: - Accent (Highlights, warnings)
    static let pomAccent = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "FFBF57")   // Brighter amber for dark mode
            : UIColor(hex: "FFB347")   // Warm amber
    })

    static let pomAccentLight = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "3D3222")   // Dark amber tint
            : UIColor(hex: "FFF4E5")   // Light amber
    })

    // MARK: - Text
    static let pomTextPrimary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "F5F5F5")   // Off-white
            : UIColor(hex: "1A1A1A")   // Near black
    })

    static let pomTextSecondary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "A0A0A0")   // Light gray
            : UIColor(hex: "6B7280")   // Cool gray
    })

    static let pomTextTertiary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "707070")   // Medium gray
            : UIColor(hex: "9CA3AF")   // Muted
    })

    // MARK: - Semantic
    static let pomDestructive = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "FF5555")   // Brighter red for dark mode
            : UIColor(hex: "EF4444")   // Red
    })

    // MARK: - Shield/Limits (Cyan for protective feel)
    static let pomShieldActive = Color(hex: "00D9FF")   // Bright cyan
    static let pomShieldInactive = Color(hex: "4A5568") // Muted gray

    // MARK: - Rewards (Stardust gold)
    static let pomStardust = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "FFD700")   // Bright gold for dark mode
            : UIColor(hex: "F5A623")   // Warm gold
    })

    static let pomStardustLight = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "3D3522")   // Dark gold tint
            : UIColor(hex: "FFF8E7")   // Light gold
    })

    static let pomBorder = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "3A3A3A")   // Dark border
            : UIColor(hex: "E5E7EB")   // Light border
    })

    // MARK: - Legacy aliases (for migration)
    static let pomPeach = pomPrimary
    static let pomCream = pomBackground
    static let pomSage = pomSecondary
    static let pomBrown = pomTextPrimary
    static let pomLightBrown = pomTextSecondary

    // MARK: - Static dark mode colors (for specific use cases)
    static let pomDarkBackground = Color(hex: "121212")
    static let pomDarkCard = Color(hex: "1E1E1E")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - UIColor Extension for Hex
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
