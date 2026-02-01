import SwiftUI

extension Font {
    // Timer display - Bold with monospaced digits for alignment
    static let timerDisplay = Font.system(size: 72, weight: .bold, design: .rounded)
        .monospacedDigit()

    // Heading 1 - Primary section titles
    static let pomHeading1 = Font.system(size: 28, weight: .bold, design: .default)

    // Heading 2 - Secondary headings
    static let pomHeading2 = Font.system(size: 20, weight: .semibold, design: .default)

    // Body text - descriptions and labels
    static let pomBody = Font.system(size: 16, weight: .medium, design: .default)

    // Caption - smaller text
    static let pomCaption = Font.system(size: 14, weight: .regular, design: .default)

    // Button text
    static let pomButton = Font.system(size: 17, weight: .semibold, design: .default)

    // Legacy aliases (for migration)
    static let pomHeading = pomHeading1
}
