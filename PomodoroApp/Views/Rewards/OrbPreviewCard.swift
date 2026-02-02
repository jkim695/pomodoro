import SwiftUI

/// Card displaying an orb style preview for collection grids
struct OrbPreviewCard: View {
    let style: OrbStyle
    let isOwned: Bool
    let isEquipped: Bool
    var starLevel: Int = 1
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Mini orb preview
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [style.glowColor.opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)

                    // Orb sphere
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    style.primaryColor.opacity(0.6),
                                    style.primaryColor,
                                    style.primaryColor.opacity(0.9)
                                ],
                                center: UnitPoint(x: 0.35, y: 0.35),
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            // Secondary color accent
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            style.secondaryColor.opacity(0.4),
                                            Color.clear
                                        ],
                                        center: UnitPoint(x: 0.7, y: 0.7),
                                        startRadius: 0,
                                        endRadius: 25
                                    )
                                )
                        )
                        .overlay(
                            // Highlight
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.8),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 12
                                    )
                                )
                                .frame(width: 18, height: 18)
                                .offset(x: -10, y: -10)
                        )
                        .shadow(color: style.glowColor.opacity(0.5), radius: 8, x: 0, y: 4)

                    // Lock overlay for unowned
                    if !isOwned {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 50, height: 50)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    // Equipped badge
                    if isEquipped {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.pomSecondary)
                            .background(Circle().fill(Color.white).padding(-2))
                            .offset(x: 20, y: -20)
                    }

                    // Star badge for owned orbs with 2+ stars
                    if isOwned && starLevel > 1 {
                        StarBadge(level: starLevel)
                            .offset(x: 0, y: 32)
                    }
                }

                // Name and price/status
                VStack(spacing: 4) {
                    Text(style.name)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.pomTextPrimary)
                        .lineLimit(1)

                    if isOwned {
                        Text(isEquipped ? "Equipped" : "Owned")
                            .font(.caption2)
                            .foregroundColor(.pomTextSecondary)
                    } else {
                        HStack(spacing: 2) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text("\(style.price)")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.pomTextSecondary)
                        }
                    }
                }
            }
            .frame(width: 100)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.pomCardBackground)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isEquipped ? Color.pomSecondary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(style.name) orb\(isOwned ? (starLevel > 1 ? ", \(starLevel) star" : "") : ", locked")\(isEquipped ? ", currently equipped" : "")")
        .accessibilityHint(isOwned ? (isEquipped ? "" : "Double tap to view details") : "Double tap to view unlock options, costs \(style.price) Stardust")
        .accessibilityAddTraits(isEquipped ? .isSelected : [])
    }
}

#Preview {
    HStack(spacing: 16) {
        OrbPreviewCard(
            style: OrbCatalog.all[0],
            isOwned: true,
            isEquipped: true
        )
        OrbPreviewCard(
            style: OrbCatalog.all[2],
            isOwned: true,
            isEquipped: false
        )
        OrbPreviewCard(
            style: OrbCatalog.all[4],
            isOwned: false,
            isEquipped: false
        )
    }
    .padding()
    .background(Color.pomBackground)
}
