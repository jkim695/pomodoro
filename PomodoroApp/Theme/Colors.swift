import SwiftUI

extension Color {
    // Primary palette - warm earth tones
    static let pomPeach = Color(hex: "FFCBA4")      // Primary accent
    static let pomCream = Color(hex: "FFF8E7")      // Background
    static let pomSage = Color(hex: "B2C9AD")       // Secondary/progress
    static let pomBrown = Color(hex: "4A3728")      // Text
    static let pomLightBrown = Color(hex: "8B7355") // Secondary text

    // Dark mode variants
    static let pomDarkBackground = Color(hex: "2C2419")
    static let pomDarkCard = Color(hex: "3D3226")

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

// MARK: - Adaptive Colors for Dark Mode
struct AdaptiveColors {
    @Environment(\.colorScheme) static var colorScheme

    static var background: Color {
        Color.pomCream
    }

    static var cardBackground: Color {
        Color.pomCream.opacity(0.8)
    }

    static var primaryText: Color {
        Color.pomBrown
    }

    static var secondaryText: Color {
        Color.pomLightBrown
    }
}
