import SwiftUI

/// Quick orb selector sheet for fast switching between owned orbs
struct QuickOrbSelectorView: View {
    @EnvironmentObject var rewardsManager: RewardsManager
    @Environment(\.dismiss) private var dismiss

    // 3-column grid for compact display
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Currently equipped preview
                    currentOrbPreview

                    Divider()
                        .padding(.horizontal)

                    // Owned orbs grid
                    if rewardsManager.ownedStyles.count > 1 {
                        orbsGrid
                    } else {
                        emptyState
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.pomBackground)
            .navigationTitle("Choose Orb")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.pomAccent)
                }
            }
        }
    }

    // MARK: - Current Orb Preview

    private var currentOrbPreview: some View {
        VStack(spacing: 12) {
            GradientOrbView(
                state: .idle,
                size: 80,
                style: rewardsManager.equippedStyle,
                starLevel: rewardsManager.starLevel(for: rewardsManager.equippedStyle.id)
            )

            Text(rewardsManager.equippedStyle.name)
                .font(.headline)
                .foregroundColor(.pomTextPrimary)

            Text("Currently Equipped")
                .font(.caption)
                .foregroundColor(.pomTextSecondary)
        }
        .padding()
    }

    // MARK: - Orbs Grid

    private var orbsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(rewardsManager.ownedStyles) { style in
                QuickOrbCard(
                    style: style,
                    isEquipped: rewardsManager.collection.isEquipped(style.id),
                    starLevel: rewardsManager.starLevel(for: style.id)
                ) {
                    selectOrb(style)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.pomTextTertiary)

            Text("Only one orb owned")
                .font(.subheadline)
                .foregroundColor(.pomTextSecondary)

            Text("Earn more Stardust to unlock new orbs!")
                .font(.caption)
                .foregroundColor(.pomTextTertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Actions

    private func selectOrb(_ style: OrbStyle) {
        guard !rewardsManager.collection.isEquipped(style.id) else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        _ = rewardsManager.equip(style)

        // Brief delay for visual feedback before dismissing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}

// MARK: - Quick Orb Card

/// Compact orb card for quick selection
private struct QuickOrbCard: View {
    let style: OrbStyle
    let isEquipped: Bool
    let starLevel: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Mini orb preview
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [style.glowColor.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)

                    // Orb sphere
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    style.primaryColor.opacity(0.6),
                                    style.primaryColor
                                ],
                                center: UnitPoint(x: 0.35, y: 0.35),
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            // Highlight
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.white.opacity(0.7), Color.clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 10
                                    )
                                )
                                .frame(width: 14, height: 14)
                                .offset(x: -8, y: -8)
                        )
                        .shadow(color: style.glowColor.opacity(0.4), radius: 6, x: 0, y: 3)

                    // Equipped checkmark
                    if isEquipped {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.pomSecondary)
                            .background(Circle().fill(Color.white).padding(-2))
                            .offset(x: 16, y: -16)
                    }

                    // Star badge for 2+ stars
                    if starLevel > 1 {
                        StarBadge(level: starLevel)
                            .scaleEffect(0.8)
                            .offset(x: 0, y: 26)
                    }
                }

                // Name
                Text(style.name)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.pomTextPrimary)
                    .lineLimit(1)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pomCardBackground)
                    .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isEquipped ? Color.pomSecondary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickOrbSelectorView()
        .environmentObject(RewardsManager.shared)
}
