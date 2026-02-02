import SwiftUI

/// Badge displaying Stardust currency amount
struct StardustBadge: View {
    let amount: Int
    var showIcon: Bool = true
    var size: BadgeSize = .medium

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }

        var fontSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            case .large: return .title3
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 12
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: "sparkles")
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .foregroundStyle(stardustGradient)
            }

            Text(formattedAmount)
                .font(size.fontSize.weight(.semibold))
                .foregroundStyle(Color.pomTextPrimary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding * 0.6)
        .background(
            Capsule()
                .fill(Color.pomCardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(amount) Stardust")
    }

    private var formattedAmount: String {
        if amount >= 1000 {
            let thousands = Double(amount) / 1000.0
            return String(format: "%.1fK", thousands)
        }
        return "\(amount)"
    }

    private var stardustGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        StardustBadge(amount: 42, size: .small)
        StardustBadge(amount: 1234, size: .medium)
        StardustBadge(amount: 99999, size: .large)
        StardustBadge(amount: 500, showIcon: false)
    }
    .padding()
    .background(Color.pomBackground)
}
