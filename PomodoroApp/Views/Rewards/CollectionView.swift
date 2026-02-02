import SwiftUI

/// Grid display of owned orb styles
struct CollectionView: View {
    @EnvironmentObject var rewardsManager: RewardsManager
    @State private var selectedStyle: OrbStyle?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with count
                HStack {
                    Text("Your Collection")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.pomTextPrimary)

                    Spacer()

                    Text("\(rewardsManager.ownedStyles.count) / \(OrbCatalog.all.count)")
                        .font(.subheadline)
                        .foregroundColor(.pomTextSecondary)
                }
                .padding(.horizontal)

                // Currently equipped
                VStack(alignment: .leading, spacing: 12) {
                    Text("Currently Equipped")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.pomTextSecondary)
                        .padding(.horizontal)

                    HStack(spacing: 16) {
                        // Mini orb preview with star level
                        GradientOrbView(
                            state: .idle,
                            size: 60,
                            style: rewardsManager.equippedStyle,
                            starLevel: rewardsManager.starLevel(for: rewardsManager.equippedStyle.id)
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(rewardsManager.equippedStyle.name)
                                    .font(.headline)
                                    .foregroundColor(.pomTextPrimary)

                                let equippedStarLevel = rewardsManager.starLevel(for: rewardsManager.equippedStyle.id)
                                if equippedStarLevel > 1 {
                                    StarBadge(level: equippedStarLevel)
                                }
                            }

                            Text(rewardsManager.equippedStyle.rarity.displayName)
                                .font(.caption)
                                .foregroundColor(rewardsManager.equippedStyle.rarity.color)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.pomCardBackground)
                    )
                    .padding(.horizontal)
                }

                // Owned orbs grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Owned Orbs")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.pomTextSecondary)
                        .padding(.horizontal)

                    if rewardsManager.ownedStyles.isEmpty {
                        Text("Complete focus sessions to earn Stardust and unlock new orbs!")
                            .font(.subheadline)
                            .foregroundColor(.pomTextTertiary)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(rewardsManager.ownedStyles) { style in
                                OrbPreviewCard(
                                    style: style,
                                    isOwned: true,
                                    isEquipped: rewardsManager.collection.isEquipped(style.id),
                                    starLevel: rewardsManager.starLevel(for: style.id)
                                ) {
                                    selectedStyle = style
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Locked orbs teaser
                if !rewardsManager.lockedStyles.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Locked")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.pomTextSecondary)

                            Spacer()

                            NavigationLink {
                                GachaView()
                            } label: {
                                Text("Try Gacha")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.pomPrimary)
                            }
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(rewardsManager.lockedStyles.prefix(5)) { style in
                                    OrbPreviewCard(
                                        style: style,
                                        isOwned: false,
                                        isEquipped: false
                                    ) {
                                        selectedStyle = style
                                    }
                                }

                                if rewardsManager.lockedStyles.count > 5 {
                                    NavigationLink {
                                        GachaView()
                                    } label: {
                                        VStack {
                                            Image(systemName: "ellipsis")
                                                .font(.title2)
                                                .foregroundColor(.pomTextSecondary)
                                            Text("+\(rewardsManager.lockedStyles.count - 5) more")
                                                .font(.caption)
                                                .foregroundColor(.pomTextTertiary)
                                        }
                                        .frame(width: 100, height: 130)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.pomCardBackgroundAlt)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.pomBackground)
        .sheet(item: $selectedStyle) { style in
            OrbDetailSheet(style: style)
        }
    }
}

#Preview {
    NavigationStack {
        CollectionView()
            .environmentObject(RewardsManager.shared)
    }
}
