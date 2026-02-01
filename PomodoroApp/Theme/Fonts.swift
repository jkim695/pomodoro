import SwiftUI

extension Font {
    // Timer display - large, light weight for the countdown
    static let timerDisplay = Font.system(size: 64, weight: .light, design: .rounded)

    // Headings - section titles
    static let pomHeading = Font.system(size: 24, weight: .semibold, design: .rounded)

    // Body text - descriptions and labels
    static let pomBody = Font.system(size: 16, weight: .regular, design: .rounded)

    // Caption - smaller text
    static let pomCaption = Font.system(size: 14, weight: .regular, design: .rounded)

    // Button text
    static let pomButton = Font.system(size: 18, weight: .semibold, design: .rounded)
}
