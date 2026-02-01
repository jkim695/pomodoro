import SwiftUI

/// View showing user statistics and milestone progress
struct ProgressSummaryView: View {
    @EnvironmentObject var rewardsManager: RewardsManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Stats cards
                VStack(spacing: 16) {
                    Text("Your Progress")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.pomTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Main stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            icon: "clock.fill",
                            value: formatMinutes(rewardsManager.progress.totalFocusMinutes),
                            label: "Total Focus Time",
                            color: .pomPrimary
                        )

                        StatCard(
                            icon: "checkmark.circle.fill",
                            value: "\(rewardsManager.progress.totalSessionsCompleted)",
                            label: "Sessions Completed",
                            color: .pomSecondary
                        )

                        StatCard(
                            icon: "flame.fill",
                            value: "\(rewardsManager.progress.currentStreak)",
                            label: "Current Streak",
                            color: .pomAccent
                        )

                        StatCard(
                            icon: "trophy.fill",
                            value: "\(rewardsManager.progress.longestStreak)",
                            label: "Best Streak",
                            color: Color(hex: "FFD700")
                        )
                    }

                    // Stardust summary
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Lifetime Stardust")
                                .font(.subheadline)
                                .foregroundColor(.pomTextSecondary)
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("\(rewardsManager.balance.total)")
                                    .font(.title.weight(.bold))
                                    .foregroundColor(.pomTextPrimary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Current Balance")
                                .font(.subheadline)
                                .foregroundColor(.pomTextSecondary)
                            StardustBadge(amount: rewardsManager.balance.current, size: .large)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.pomCardBackground)
                    )
                }
                .padding(.horizontal)

                // Milestones
                VStack(alignment: .leading, spacing: 16) {
                    Text("Milestones")
                        .font(.headline)
                        .foregroundColor(.pomTextPrimary)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        ForEach(Milestones.all) { milestone in
                            MilestoneRow(
                                milestone: milestone,
                                isAchieved: rewardsManager.progress.achievedMilestones.contains(milestone.id)
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // Streak bonus info
                if rewardsManager.progress.currentStreak > 1 {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.pomAccent)
                            Text("Streak Bonus Active!")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.pomTextPrimary)
                        }

                        Text("+\(Int(rewardsManager.progress.streakBonusMultiplier * 100))% Stardust on completed sessions")
                            .font(.caption)
                            .foregroundColor(.pomTextSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.pomAccent.opacity(0.15))
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.pomBackground)
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.pomTextPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(.pomTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pomCardBackground)
        )
    }
}

private struct MilestoneRow: View {
    let milestone: Milestone
    let isAchieved: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isAchieved ? Color.pomSecondary : Color.pomCardBackgroundAlt)
                    .frame(width: 40, height: 40)

                Image(systemName: isAchieved ? "checkmark" : milestone.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isAchieved ? .white : .pomTextTertiary)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isAchieved ? .pomTextPrimary : .pomTextSecondary)

                Text(milestone.requirement.progressDescription)
                    .font(.caption)
                    .foregroundColor(.pomTextTertiary)
            }

            Spacer()

            // Reward
            if isAchieved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.pomSecondary)
            } else {
                HStack(spacing: 2) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("+\(milestone.reward)")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(.pomTextTertiary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pomCardBackground)
                .opacity(isAchieved ? 1 : 0.6)
        )
    }
}

#Preview {
    NavigationStack {
        ProgressSummaryView()
            .environmentObject(RewardsManager.shared)
    }
}
