import SwiftUI

/// Main rewards tab container with navigation to Collection, Gacha, and Progress
struct RewardsTabView: View {
    @EnvironmentObject var rewardsManager: RewardsManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with balance
                    VStack(spacing: 16) {
                        Text("Rewards")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.pomTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Balance card
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Stardust")
                                    .font(.subheadline)
                                    .foregroundColor(.pomTextSecondary)

                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.title)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    Text("\(rewardsManager.balance.current)")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundColor(.pomTextPrimary)
                                        .contentTransition(.numericText())
                                }
                            }

                            Spacer()

                            // Streak indicator
                            if rewardsManager.progress.currentStreak > 0 {
                                VStack(spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(.pomAccent)
                                        Text("\(rewardsManager.progress.currentStreak)")
                                            .font(.title2.weight(.bold))
                                            .foregroundColor(.pomTextPrimary)
                                    }
                                    Text("day streak")
                                        .font(.caption)
                                        .foregroundColor(.pomTextSecondary)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.pomCardBackground)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        )
                    }
                    .padding(.horizontal)

                    // Currently equipped orb preview
                    VStack(spacing: 12) {
                        Text("Equipped Orb")
                            .font(.headline)
                            .foregroundColor(.pomTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        NavigationLink {
                            CollectionView()
                        } label: {
                            HStack(spacing: 16) {
                                GradientOrbView(
                                    state: .idle,
                                    size: 70,
                                    style: rewardsManager.equippedStyle,
                                    starLevel: rewardsManager.starLevel(for: rewardsManager.equippedStyle.id)
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(rewardsManager.equippedStyle.name)
                                            .font(.headline)
                                            .foregroundColor(.pomTextPrimary)

                                        let starLevel = rewardsManager.starLevel(for: rewardsManager.equippedStyle.id)
                                        if starLevel > 1 {
                                            StarBadge(level: starLevel)
                                        }
                                    }

                                    Text(rewardsManager.equippedStyle.rarity.displayName)
                                        .font(.caption)
                                        .foregroundColor(rewardsManager.equippedStyle.rarity.color)

                                    Text("Tap to view collection")
                                        .font(.caption)
                                        .foregroundColor(.pomTextTertiary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.pomTextTertiary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.pomCardBackground)
                            )
                            .padding(.horizontal)
                        }
                    }

                    // Quick actions
                    VStack(spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(.pomTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                            NavigationLink {
                                CollectionView()
                            } label: {
                                QuickActionCard(
                                    icon: "square.grid.2x2.fill",
                                    title: "Collection",
                                    subtitle: "\(rewardsManager.ownedStyles.count) orbs",
                                    color: .pomPrimary
                                )
                            }

                            NavigationLink {
                                GachaView()
                            } label: {
                                QuickActionCard(
                                    icon: "gift.fill",
                                    title: "Gacha",
                                    subtitle: "Pull orbs",
                                    color: .purple
                                )
                            }

                            NavigationLink {
                                ProgressSummaryView()
                            } label: {
                                QuickActionCard(
                                    icon: "chart.bar.fill",
                                    title: "Progress",
                                    subtitle: "Stats",
                                    color: .pomAccent
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Recent milestones or next milestone
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Next Milestone")
                            .font(.headline)
                            .foregroundColor(.pomTextPrimary)
                            .padding(.horizontal)

                        if let nextMilestone = nextUnachievedMilestone {
                            NavigationLink {
                                ProgressSummaryView()
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.pomCardBackgroundAlt)
                                            .frame(width: 50, height: 50)

                                        Image(systemName: nextMilestone.iconName)
                                            .font(.title3)
                                            .foregroundColor(.pomTextSecondary)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(nextMilestone.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(.pomTextPrimary)

                                        Text(nextMilestone.requirement.progressDescription)
                                            .font(.caption)
                                            .foregroundColor(.pomTextTertiary)
                                    }

                                    Spacer()

                                    HStack(spacing: 2) {
                                        Image(systemName: "sparkles")
                                            .font(.caption)
                                        Text("+\(nextMilestone.reward)")
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .foregroundColor(.pomAccent)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.pomCardBackground)
                                )
                                .padding(.horizontal)
                            }
                        } else {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(Color(hex: "FFD700"))
                                Text("All milestones achieved!")
                                    .font(.subheadline)
                                    .foregroundColor(.pomTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.pomCardBackground)
                            )
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .background(Color.pomBackground)
        }
    }

    private var nextUnachievedMilestone: Milestone? {
        Milestones.all.first { !rewardsManager.progress.achievedMilestones.contains($0.id) }
    }
}

// MARK: - Supporting Views

private struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.pomTextPrimary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.pomTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pomCardBackground)
        )
    }
}

#Preview {
    RewardsTabView()
        .environmentObject(RewardsManager.shared)
}
