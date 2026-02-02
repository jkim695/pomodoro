import SwiftUI

/// Main rewards tab container with navigation to Collection, Gacha, and Progress
struct RewardsTabView: View {
    @EnvironmentObject var rewardsManager: RewardsManager
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Adaptive horizontal padding
    private var horizontalPadding: CGFloat {
        sizeClass == .regular ? 40 : 16
    }

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
                                        .font(sizeClass == .regular ? .largeTitle : .title)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    Text("\(rewardsManager.balance.current)")
                                        .font(.system(size: sizeClass == .regular ? 44 : 36, weight: .bold, design: .rounded))
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
                                            .font(sizeClass == .regular ? .title : .title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.pomTextPrimary)
                                    }
                                    Text("day streak")
                                        .font(.caption)
                                        .foregroundColor(.pomTextSecondary)
                                }
                            }
                        }
                        .padding(sizeClass == .regular ? 24 : 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.pomCardBackground)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        )
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Your Stardust: \(rewardsManager.balance.current)\(rewardsManager.progress.currentStreak > 0 ? ", \(rewardsManager.progress.currentStreak) day streak" : "")")
                    }
                    .padding(.horizontal, horizontalPadding)

                    // Currently equipped orb preview
                    VStack(spacing: 12) {
                        Text("Equipped Orb")
                            .font(.headline)
                            .foregroundColor(.pomTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, horizontalPadding)

                        NavigationLink {
                            CollectionView()
                        } label: {
                            HStack(spacing: sizeClass == .regular ? 20 : 16) {
                                GradientOrbView(
                                    state: .idle,
                                    size: sizeClass == .regular ? 90 : 70,
                                    style: rewardsManager.equippedStyle,
                                    starLevel: rewardsManager.starLevel(for: rewardsManager.equippedStyle.id)
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rewardsManager.equippedStyle.name)
                                        .font(sizeClass == .regular ? .title3 : .headline)
                                        .foregroundColor(.pomTextPrimary)

                                    let starLevel = rewardsManager.starLevel(for: rewardsManager.equippedStyle.id)
                                    if starLevel > 1 {
                                        StarBadge(level: starLevel)
                                    }

                                    Text("Tap to view collection")
                                        .font(.caption)
                                        .foregroundColor(.pomTextTertiary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.pomTextTertiary)
                            }
                            .padding(sizeClass == .regular ? 20 : 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.pomCardBackground)
                            )
                            .padding(.horizontal, horizontalPadding)
                        }
                    }

                    // Quick actions
                    VStack(spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(.pomTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, horizontalPadding)

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: sizeClass == .regular ? 16 : 12),
                            GridItem(.flexible(), spacing: sizeClass == .regular ? 16 : 12)
                        ], spacing: sizeClass == .regular ? 16 : 12) {
                            NavigationLink {
                                CollectionView()
                            } label: {
                                QuickActionCard(
                                    icon: "square.grid.2x2.fill",
                                    title: "Collection",
                                    subtitle: "\(rewardsManager.ownedStyles.count) orbs",
                                    color: .pomPrimary,
                                    isRegular: sizeClass == .regular
                                )
                            }

                            NavigationLink {
                                GachaView()
                            } label: {
                                QuickActionCard(
                                    icon: "gift.fill",
                                    title: "Gacha",
                                    subtitle: "Pull orbs",
                                    color: .purple,
                                    isRegular: sizeClass == .regular
                                )
                            }

                            NavigationLink {
                                ProgressSummaryView()
                            } label: {
                                QuickActionCard(
                                    icon: "chart.bar.fill",
                                    title: "Progress",
                                    subtitle: "Stats",
                                    color: .pomAccent,
                                    isRegular: sizeClass == .regular
                                )
                            }

                            NavigationLink {
                                OrbNebulaView()
                            } label: {
                                QuickActionCard(
                                    icon: "sparkles",
                                    title: "Nebula",
                                    subtitle: "\(rewardsManager.orbCollectionHistory.totalCollected) orbs",
                                    color: .indigo,
                                    isRegular: sizeClass == .regular
                                )
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                    }

                    // Recent milestones or next milestone
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Next Milestone")
                            .font(.headline)
                            .foregroundColor(.pomTextPrimary)
                            .padding(.horizontal, horizontalPadding)

                        if let nextMilestone = nextUnachievedMilestone {
                            NavigationLink {
                                ProgressSummaryView()
                            } label: {
                                HStack(spacing: sizeClass == .regular ? 16 : 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.pomCardBackgroundAlt)
                                            .frame(width: sizeClass == .regular ? 60 : 50, height: sizeClass == .regular ? 60 : 50)

                                        Image(systemName: nextMilestone.iconName)
                                            .font(sizeClass == .regular ? .title2 : .title3)
                                            .foregroundColor(.pomTextSecondary)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(nextMilestone.name)
                                            .font(sizeClass == .regular ? .headline : .subheadline)
                                            .fontWeight(.medium)
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
                                            .font(sizeClass == .regular ? .headline : .subheadline)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.pomAccent)
                                }
                                .padding(sizeClass == .regular ? 20 : 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.pomCardBackground)
                                )
                                .padding(.horizontal, horizontalPadding)
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
                            .padding(sizeClass == .regular ? 20 : 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.pomCardBackground)
                            )
                            .padding(.horizontal, horizontalPadding)
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
    var isRegular: Bool = false

    var body: some View {
        VStack(spacing: isRegular ? 12 : 8) {
            Image(systemName: icon)
                .font(isRegular ? .title : .title2)
                .foregroundColor(color)

            Text(title)
                .font(isRegular ? .subheadline.weight(.semibold) : .caption.weight(.semibold))
                .foregroundColor(.pomTextPrimary)

            Text(subtitle)
                .font(isRegular ? .caption : .caption2)
                .foregroundColor(.pomTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isRegular ? 24 : 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pomCardBackground)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}

#Preview {
    RewardsTabView()
        .environmentObject(RewardsManager.shared)
}
