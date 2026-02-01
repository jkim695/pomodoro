import SwiftUI

/// Main gacha pull interface
struct GachaView: View {
    @EnvironmentObject var rewardsManager: RewardsManager
    @State private var showSinglePullResult = false
    @State private var showTenPullResult = false
    @State private var pullResults: [GachaPullResult] = []
    @State private var isPulling = false
    @State private var pullAnimationScale: CGFloat = 1.0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Balance header
                HStack {
                    Text("Gacha")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.pomTextPrimary)

                    Spacer()

                    StardustBadge(amount: rewardsManager.balance.current, size: .medium)
                }
                .padding(.horizontal)

                // Pull animation area
                GachaPullAnimationArea(
                    isPulling: isPulling,
                    scale: pullAnimationScale
                )
                .padding(.vertical, 20)

                // Pity progress indicators
                PityProgressView(counter: rewardsManager.collection.pityCounter)
                    .padding(.horizontal)

                // Pull buttons
                VStack(spacing: 16) {
                    // Single pull
                    GachaPullButton(
                        title: "Single Pull",
                        cost: GachaConfig.singlePullCost,
                        canAfford: rewardsManager.canAffordSinglePull(),
                        isPulling: isPulling
                    ) {
                        performSinglePull()
                    }

                    // Ten pull
                    GachaPullButton(
                        title: "10x Pull",
                        cost: GachaConfig.tenPullCost,
                        discount: "20% off",
                        canAfford: rewardsManager.canAffordTenPull(),
                        isPulling: isPulling
                    ) {
                        performTenPull()
                    }
                }
                .padding(.horizontal)

                // Drop rates disclosure
                DropRatesDisclosure()
                    .padding(.horizontal)

                // Recent pull history
                if !rewardsManager.collection.pullHistory.recent.isEmpty {
                    RecentPullsSection(pulls: rewardsManager.collection.pullHistory.recent)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.pomBackground)
        .navigationTitle("Gacha")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSinglePullResult) {
            GachaPullResultView(results: pullResults) {
                showSinglePullResult = false
                pullResults = []
            }
        }
        .sheet(isPresented: $showTenPullResult) {
            GachaPullResultView(results: pullResults) {
                showTenPullResult = false
                pullResults = []
            }
        }
    }

    private func performSinglePull() {
        isPulling = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        // Animate the pull
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            pullAnimationScale = 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                pullAnimationScale = 1.2
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                pullAnimationScale = 1.0
            }

            switch rewardsManager.performSinglePull() {
            case .success(let result):
                pullResults = [result]
                isPulling = false
                showSinglePullResult = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .failure:
                isPulling = false
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    private func performTenPull() {
        isPulling = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        // More dramatic animation for 10-pull
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            pullAnimationScale = 0.7
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                pullAnimationScale = 1.3
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                pullAnimationScale = 1.0
            }

            switch rewardsManager.performTenPull() {
            case .success(let results):
                pullResults = results
                isPulling = false
                showTenPullResult = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .failure:
                isPulling = false
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}

// MARK: - Pull Animation Area

private struct GachaPullAnimationArea: View {
    let isPulling: Bool
    let scale: CGFloat

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.pomPrimary.opacity(0.3),
                            Color.pomPrimary.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .blur(radius: 20)

            // Spinning ring when pulling
            if isPulling {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.pomPrimary, .pomSecondary, .pomPrimary],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
            }

            // Capsule/orb visual
            ZStack {
                // Outer shell
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "FFD700"),
                                Color(hex: "FFA500"),
                                Color(hex: "FF8C00")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                // Inner highlight
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 100, height: 100)

                // Question mark or sparkle
                Image(systemName: isPulling ? "sparkles" : "questionmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .scaleEffect(scale)
            .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 20, x: 0, y: 0)
        }
        .frame(height: 200)
    }
}

#Preview {
    NavigationStack {
        GachaView()
            .environmentObject(RewardsManager.shared)
    }
}
