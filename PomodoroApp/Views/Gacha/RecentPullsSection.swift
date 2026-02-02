import SwiftUI

/// Shows recent gacha pull history
struct RecentPullsSection: View {
    let pulls: [GachaPullResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Pulls")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.pomTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(pulls) { pull in
                        RecentPullCard(pull: pull)
                    }
                }
            }
        }
    }
}

private struct RecentPullCard: View {
    let pull: GachaPullResult

    var body: some View {
        VStack(spacing: 6) {
            // Mini orb
            if let style = OrbCatalog.style(for: pull.orbId) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [style.primaryColor.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [style.primaryColor, style.secondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)

                    // Highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.5), Color.clear],
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: 0,
                                endRadius: 10
                            )
                        )
                        .frame(width: 28, height: 28)
                }
            }

            // Rarity indicator
            Circle()
                .fill(pull.rarity.color)
                .frame(width: 6, height: 6)

            // Shards
            HStack(spacing: 2) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 6))
                Text("+\(pull.shardsAwarded)")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(.pomTextSecondary)
        }
        .frame(width: 60)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.pomCardBackground)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(pull.orbName), \(pull.rarity.displayName), plus \(pull.shardsAwarded) shards")
    }
}

#Preview {
    RecentPullsSection(pulls: [
        GachaPullResult(orbId: "orb_cosmic", orbName: "Cosmic Dust", rarity: .epic, shardsAwarded: 20),
        GachaPullResult(orbId: "orb_sunset", orbName: "Sunset Glow", rarity: .uncommon, shardsAwarded: 5),
        GachaPullResult(orbId: "orb_default", orbName: "Focus Orb", rarity: .common, shardsAwarded: 3),
        GachaPullResult(orbId: "orb_void", orbName: "Void Walker", rarity: .legendary, shardsAwarded: 40),
        GachaPullResult(orbId: "orb_rose", orbName: "Rose Quartz", rarity: .rare, shardsAwarded: 10)
    ])
    .padding()
    .background(Color.pomBackground)
}
