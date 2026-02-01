import SwiftUI

/// Shows shard progress toward unlocking or upgrading an orb
struct ShardProgressView: View {
    let style: OrbStyle
    let shardCount: Int
    let starLevel: Int
    let isOwned: Bool

    private var targetShards: Int {
        if !isOwned {
            return style.rarity.shardsToUnlock
        } else if starLevel < OrbStarLevels.maxStarLevel {
            return style.rarity.shardsPerStar
        }
        return 0
    }

    private var progress: Double {
        guard targetShards > 0 else { return 1.0 }
        return min(Double(shardCount) / Double(targetShards), 1.0)
    }

    private var isReady: Bool {
        shardCount >= targetShards && targetShards > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                if !isOwned {
                    Text("Unlock Progress")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.pomTextSecondary)
                } else if starLevel < OrbStarLevels.maxStarLevel {
                    HStack(spacing: 4) {
                        Text("Upgrade to")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.pomTextSecondary)
                        StarBadge(level: starLevel + 1)
                    }
                } else {
                    Text("Max Level")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.pomSecondary)
                }

                Spacer()

                if targetShards > 0 {
                    Text("\(shardCount)/\(targetShards)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.pomTextPrimary)
                }
            }

            // Progress bar
            if targetShards > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.pomCardBackgroundAlt)

                        // Fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [style.primaryColor, style.secondaryColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(progress))
                    }
                }
                .frame(height: 8)
            }

            // Ready indicator
            if isReady {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color(hex: "FFD700"))
                    Text(isOwned ? "Ready to upgrade!" : "Ready to unlock!")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color(hex: "FFD700"))
                }
            }
        }
    }
}

/// Compact shard count display for cards
struct ShardCountBadge: View {
    let count: Int
    let required: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 8))
            Text("\(count)/\(required)")
                .font(.caption2.weight(.semibold))
        }
        .foregroundColor(.pomTextSecondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.pomCardBackground)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        // Not owned, some progress
        ShardProgressView(
            style: OrbCatalog.all[2],
            shardCount: 15,
            starLevel: 0,
            isOwned: false
        )

        // Not owned, ready to unlock
        ShardProgressView(
            style: OrbCatalog.all[2],
            shardCount: 50,
            starLevel: 0,
            isOwned: false
        )

        // Owned, upgrade progress
        ShardProgressView(
            style: OrbCatalog.all[2],
            shardCount: 30,
            starLevel: 2,
            isOwned: true
        )

        // Owned, ready to upgrade
        ShardProgressView(
            style: OrbCatalog.all[2],
            shardCount: 50,
            starLevel: 2,
            isOwned: true
        )

        // Max level
        ShardProgressView(
            style: OrbCatalog.all[2],
            shardCount: 25,
            starLevel: 5,
            isOwned: true
        )

        // Shard count badge
        ShardCountBadge(count: 15, required: 50)
    }
    .padding()
    .background(Color.pomBackground)
}
