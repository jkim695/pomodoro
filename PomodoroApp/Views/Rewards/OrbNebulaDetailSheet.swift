import SwiftUI

/// Detail sheet shown when tapping an orb in the nebula
/// Shows orb info, collection date, and total count of this type
struct OrbNebulaDetailSheet: View {
    let collectedOrb: CollectedOrb
    @EnvironmentObject var rewardsManager: RewardsManager
    @Environment(\.dismiss) private var dismiss

    private var style: OrbStyle? {
        OrbCatalog.style(for: collectedOrb.orbStyleId)
    }

    private var totalOfThisType: Int {
        rewardsManager.orbCollectionHistory.count(for: collectedOrb.orbStyleId)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.pomTextTertiary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            if let style = style {
                ScrollView {
                    VStack(spacing: 24) {
                        // Orb preview
                        GradientOrbView(
                            state: .idle,
                            size: 140,
                            style: style,
                            starLevel: rewardsManager.starLevel(for: style.id)
                        )
                        .padding(.top, 24)

                        // Orb name and rarity
                        VStack(spacing: 8) {
                            Text(style.name)
                                .font(.title.weight(.bold))
                                .foregroundColor(.pomTextPrimary)

                            Text(style.rarity.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(style.rarity.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(style.rarity.color.opacity(0.15))
                                )
                        }

                        // Stats cards
                        VStack(spacing: 12) {
                            // Collection date
                            statCard(
                                icon: "calendar",
                                title: "Collected",
                                value: formattedDate(collectedOrb.collectedAt)
                            )

                            // Total of this type
                            statCard(
                                icon: "square.stack.3d.up.fill",
                                title: "Total \(style.name) Collected",
                                value: "\(totalOfThisType)"
                            )

                            // Total sessions
                            statCard(
                                icon: "clock.fill",
                                title: "Total Sessions",
                                value: "\(rewardsManager.progress.totalSessionsCompleted)"
                            )
                        }
                        .padding(.horizontal)

                        // Description
                        Text(style.description)
                            .font(.subheadline)
                            .foregroundColor(.pomTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer(minLength: 40)
                    }
                }
            } else {
                // Fallback for unknown orb
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.pomTextTertiary)

                    Text("Unknown Orb")
                        .font(.headline)
                        .foregroundColor(.pomTextSecondary)
                }
                .padding(.top, 60)
            }
        }
        .background(Color.pomBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Stat Card

    private func statCard(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.pomCardBackgroundAlt)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.pomPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.pomTextTertiary)

                Text(value)
                    .font(.headline)
                    .foregroundColor(.pomTextPrimary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pomCardBackground)
        )
    }

    // MARK: - Date Formatting

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    OrbNebulaDetailSheet(
        collectedOrb: CollectedOrb(orbStyleId: "orb_cosmic")
    )
    .environmentObject(RewardsManager.shared)
}
