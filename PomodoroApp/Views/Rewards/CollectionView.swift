import SwiftUI

/// Grid display of owned orb styles
struct CollectionView: View {
    @EnvironmentObject var rewardsManager: RewardsManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedStyle: OrbStyle?

    /// Adaptive columns based on device size class
    private var columns: [GridItem] {
        let columnCount = sizeClass == .regular ? 4 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
    }

    /// Adaptive horizontal padding
    private var horizontalPadding: CGFloat {
        sizeClass == .regular ? 32 : 16
    }

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
                .padding(.horizontal, horizontalPadding)

                // Currently equipped
                VStack(alignment: .leading, spacing: 12) {
                    Text("Currently Equipped")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.pomTextSecondary)
                        .padding(.horizontal, horizontalPadding)

                    HStack(spacing: 16) {
                        // Mini orb preview with star level (larger on iPad)
                        GradientOrbView(
                            state: .idle,
                            size: sizeClass == .regular ? 80 : 60,
                            style: rewardsManager.equippedStyle,
                            starLevel: rewardsManager.starLevel(for: rewardsManager.equippedStyle.id)
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(rewardsManager.equippedStyle.name)
                                .font(sizeClass == .regular ? .title3 : .headline)
                                .foregroundColor(.pomTextPrimary)

                            HStack(spacing: 8) {
                                let equippedStarLevel = rewardsManager.starLevel(for: rewardsManager.equippedStyle.id)
                                if equippedStarLevel > 1 {
                                    StarBadge(level: equippedStarLevel)
                                }

                                Text(rewardsManager.equippedStyle.rarity.displayName)
                                    .font(.caption)
                                    .foregroundColor(rewardsManager.equippedStyle.rarity.color)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                    .padding(sizeClass == .regular ? 20 : 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.pomCardBackground)
                    )
                    .padding(.horizontal, horizontalPadding)
                }

                // Owned orbs grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Owned Orbs")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.pomTextSecondary)
                        .padding(.horizontal, horizontalPadding)

                    if rewardsManager.ownedStyles.isEmpty {
                        Text("Complete focus sessions to earn Stardust and unlock new orbs!")
                            .font(.subheadline)
                            .foregroundColor(.pomTextTertiary)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        LazyVGrid(columns: columns, spacing: sizeClass == .regular ? 20 : 16) {
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
                        .padding(.horizontal, horizontalPadding)
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
                        .padding(.horizontal, horizontalPadding)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: sizeClass == .regular ? 16 : 12) {
                                ForEach(rewardsManager.lockedStyles.prefix(sizeClass == .regular ? 8 : 5)) { style in
                                    OrbPreviewCard(
                                        style: style,
                                        isOwned: false,
                                        isEquipped: false
                                    ) {
                                        selectedStyle = style
                                    }
                                }

                                let maxVisible = sizeClass == .regular ? 8 : 5
                                if rewardsManager.lockedStyles.count > maxVisible {
                                    NavigationLink {
                                        GachaView()
                                    } label: {
                                        VStack {
                                            Image(systemName: "ellipsis")
                                                .font(.title2)
                                                .foregroundColor(.pomTextSecondary)
                                            Text("+\(rewardsManager.lockedStyles.count - maxVisible) more")
                                                .font(.caption)
                                                .foregroundColor(.pomTextTertiary)
                                        }
                                        .frame(width: sizeClass == .regular ? 120 : 100, height: sizeClass == .regular ? 150 : 130)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.pomCardBackgroundAlt)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
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
