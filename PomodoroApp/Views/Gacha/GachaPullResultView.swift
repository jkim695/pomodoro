import SwiftUI

/// Displays gacha pull results with reveal animation
struct GachaPullResultView: View {
    let results: [GachaPullResult]
    let onDismiss: () -> Void

    @State private var revealedCount = 0
    @State private var showAll = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Title
                Text(results.count == 1 ? "Pull Result" : "10x Pull Results")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)

                // Results display
                if results.count == 1 {
                    // Single pull - large display
                    if let result = results.first {
                        SinglePullResultCard(
                            result: result,
                            revealed: revealedCount > 0
                        )
                    }
                } else {
                    // 10-pull - grid display
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                                PullResultCard(
                                    result: result,
                                    revealed: showAll || index < revealedCount
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 400)
                }

                // Summary
                if showAll || revealedCount == results.count {
                    PullSummaryView(results: results)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Actions
                HStack(spacing: 16) {
                    if !showAll && revealedCount < results.count {
                        Button("Skip") {
                            withAnimation {
                                showAll = true
                                revealedCount = results.count
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Text("Continue")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.pomPrimary)
                            )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 32)
        }
        .onAppear {
            revealCards()
        }
    }

    private func revealCards() {
        let delay = results.count == 1 ? 0.5 : 0.2
        for i in 0..<results.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * delay) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    revealedCount = i + 1
                }

                // Haptic based on rarity
                let rarity = results[i].rarity
                switch rarity {
                case .legendary:
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                case .epic:
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                case .rare:
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                default:
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
    }
}

// MARK: - Single Pull Result (Large)

struct SinglePullResultCard: View {
    let result: GachaPullResult
    let revealed: Bool

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            if revealed {
                // Orb preview
                if let style = OrbCatalog.style(for: result.orbId) {
                    GradientOrbView(state: .idle, size: 120, style: style)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .onAppear {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                scale = 1.0
                                opacity = 1.0
                            }
                        }
                }

                // Info
                VStack(spacing: 8) {
                    Text(result.orbName)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)

                    // Rarity badge
                    Text(result.rarity.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(result.rarity.color)
                        )

                    // Shards awarded
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.caption)
                        Text("+\(result.shardsAwarded) shards")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(result.rarity.color)

                    if result.wasGuaranteed {
                        Text("Pity Guaranteed!")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.pomSecondary)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                // Unrevealed state
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "questionmark")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.3))
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            revealed ? result.rarity.color.opacity(0.5) : Color.white.opacity(0.1),
                            lineWidth: 2
                        )
                )
        )
    }
}

// MARK: - Pull Result Card (Grid)

struct PullResultCard: View {
    let result: GachaPullResult
    let revealed: Bool

    var body: some View {
        VStack(spacing: 8) {
            if revealed {
                // Mini orb preview
                if let style = OrbCatalog.style(for: result.orbId) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [style.primaryColor.opacity(0.4), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [style.primaryColor, style.secondaryColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        // Highlight
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.6), Color.clear],
                                    center: UnitPoint(x: 0.3, y: 0.3),
                                    startRadius: 0,
                                    endRadius: 15
                                )
                            )
                            .frame(width: 40, height: 40)
                    }
                }

                Text(result.orbName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 2) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 8))
                    Text("+\(result.shardsAwarded)")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundColor(result.rarity.color)
            } else {
                // Unrevealed
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "questionmark")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.3))
                    )

                Text("???")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))

                Text("...")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.2))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            revealed ? result.rarity.color.opacity(0.4) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Pull Summary

struct PullSummaryView: View {
    let results: [GachaPullResult]

    private var totalShards: Int {
        results.reduce(0) { $0 + $1.shardsAwarded }
    }

    private var rarityCounts: [(OrbRarity, Int)] {
        let counts = Dictionary(grouping: results, by: { $0.rarity })
        return [OrbRarity.legendary, .epic, .rare, .uncommon, .common]
            .compactMap { rarity in
                guard let count = counts[rarity]?.count, count > 0 else { return nil }
                return (rarity, count)
            }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Total shards
            HStack(spacing: 6) {
                Image(systemName: "diamond.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("Total: +\(totalShards) shards")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
            }

            // Rarity breakdown
            HStack(spacing: 12) {
                ForEach(rarityCounts, id: \.0) { rarity, count in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(rarity.color)
                            .frame(width: 8, height: 8)
                        Text("\(count)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

#Preview {
    GachaPullResultView(
        results: [
            GachaPullResult(orbId: "orb_cosmic", orbName: "Cosmic Dust", rarity: .epic, shardsAwarded: 20),
            GachaPullResult(orbId: "orb_sunset", orbName: "Sunset Glow", rarity: .uncommon, shardsAwarded: 5),
            GachaPullResult(orbId: "orb_default", orbName: "Focus Orb", rarity: .common, shardsAwarded: 3),
            GachaPullResult(orbId: "orb_aurora", orbName: "Aurora", rarity: .uncommon, shardsAwarded: 5),
            GachaPullResult(orbId: "orb_rose", orbName: "Rose Quartz", rarity: .rare, shardsAwarded: 10),
            GachaPullResult(orbId: "orb_ocean", orbName: "Ocean Mist", rarity: .common, shardsAwarded: 3),
            GachaPullResult(orbId: "orb_crimson", orbName: "Crimson Nebula", rarity: .rare, shardsAwarded: 10),
            GachaPullResult(orbId: "orb_default", orbName: "Focus Orb", rarity: .common, shardsAwarded: 3),
            GachaPullResult(orbId: "orb_sunset", orbName: "Sunset Glow", rarity: .uncommon, shardsAwarded: 5),
            GachaPullResult(orbId: "orb_void", orbName: "Void Walker", rarity: .legendary, shardsAwarded: 40, wasGuaranteed: true)
        ]
    ) {}
}
