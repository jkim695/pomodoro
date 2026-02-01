import SwiftUI

/// Styled button for gacha pulls
struct GachaPullButton: View {
    let title: String
    let cost: Int
    var discount: String? = nil
    let canAfford: Bool
    let isPulling: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline.weight(.semibold))

                        if let discount = discount {
                            Text(discount)
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.pomSecondary)
                                )
                        }
                    }

                    if !canAfford {
                        Text("Not enough Stardust")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    }
                }

                Spacer()

                if isPulling {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.subheadline)
                        Text("\(cost)")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(canAfford ? Color.pomPrimary : Color.pomCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        canAfford
                            ? Color.white.opacity(0.2)
                            : Color.pomTextTertiary.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .foregroundColor(canAfford ? .white : .pomTextSecondary)
        }
        .disabled(!canAfford || isPulling)
    }
}

#Preview {
    VStack(spacing: 16) {
        GachaPullButton(
            title: "Single Pull",
            cost: 15,
            canAfford: true,
            isPulling: false
        ) {}

        GachaPullButton(
            title: "10x Pull",
            cost: 120,
            discount: "20% off",
            canAfford: true,
            isPulling: false
        ) {}

        GachaPullButton(
            title: "Single Pull",
            cost: 15,
            canAfford: false,
            isPulling: false
        ) {}

        GachaPullButton(
            title: "10x Pull",
            cost: 120,
            discount: "20% off",
            canAfford: true,
            isPulling: true
        ) {}
    }
    .padding()
    .background(Color.pomBackground)
}
