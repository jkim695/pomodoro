import SwiftUI

/// Main view showing ALL collected orbs in a space-like nebula visualization
/// Similar to Forest app's tree view - each completed session adds an orb
struct OrbNebulaView: View {
    @EnvironmentObject var rewardsManager: RewardsManager
    @State private var selectedOrbIndex: Int?
    @State private var show3D: Bool = true
    @Environment(\.dismiss) private var dismiss

    private var collectedOrbs: [CollectedOrb] {
        rewardsManager.orbCollectionHistory.collectedOrbs
    }

    /// Check if 3D view is available (iOS 18.0+)
    private var is3DAvailable: Bool {
        if #available(iOS 18.0, *) {
            return true
        }
        return false
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark space background
                LinearGradient(
                    colors: [
                        Color(hex: "0A0A1A"),
                        Color(hex: "0D1421"),
                        Color(hex: "0A0A1A")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if collectedOrbs.isEmpty {
                    emptyStateView
                } else if show3D && is3DAvailable {
                    // 3D RealityKit view (iOS 18.0+)
                    if #available(iOS 18.0, *) {
                        OrbNebula3DView(
                            orbStyleIds: rewardsManager.orbCollectionHistory.allOrbStyleIds,
                            onOrbTapped: { index in
                                selectedOrbIndex = index
                            }
                        )
                    }
                } else {
                    // 2D Canvas view (fallback for iOS < 18.0 or when 2D is selected)
                    OrbNebulaCanvas(
                        orbStyleIds: rewardsManager.orbCollectionHistory.allOrbStyleIds,
                        size: geometry.size,
                        onOrbTapped: { index in
                            selectedOrbIndex = index
                        }
                    )
                }

                // Header overlay
                VStack {
                    headerView
                    Spacer()

                    // 2D/3D toggle and stats footer
                    if !collectedOrbs.isEmpty {
                        // Only show toggle on iOS 18.0+ where 3D is available
                        if is3DAvailable {
                            HStack {
                                Spacer()
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        show3D.toggle()
                                    }
                                } label: {
                                    Image(systemName: show3D ? "square.grid.2x2" : "cube")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.15))
                                        )
                                }
                                .padding(.trailing, 16)
                                .padding(.bottom, 8)
                            }
                        }

                        statsFooter
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Your Nebula")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $selectedOrbIndex) { index in
            if index < collectedOrbs.count {
                let collectedOrb = collectedOrbs[index]
                OrbNebulaDetailSheet(collectedOrb: collectedOrb)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("\(collectedOrbs.count)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.3), radius: 10)

            Text(collectedOrbs.count == 1 ? "Orb Collected" : "Orbs Collected")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 80)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 70))
                .foregroundColor(.white.opacity(0.25))

            Text("Your Nebula Awaits")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))

            Text("Complete focus sessions to collect orbs\nand watch your nebula grow")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Stats Footer

    private var statsFooter: some View {
        let breakdown = rewardsManager.orbCollectionHistory.collectionBreakdown()

        return VStack(spacing: 12) {
            // Orb type breakdown
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(breakdown.prefix(5), id: \.orbStyleId) { item in
                        if let style = OrbCatalog.style(for: item.orbStyleId) {
                            OrbTypeChip(style: style, count: item.count)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Orb Type Chip

private struct OrbTypeChip: View {
    let style: OrbStyle
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [style.primaryColor.opacity(0.9), style.primaryColor],
                        center: .center,
                        startRadius: 0,
                        endRadius: 10
                    )
                )
                .frame(width: 20, height: 20)
                .shadow(color: style.glowColor.opacity(0.5), radius: 4)

            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Int Identifiable Extension

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

// MARK: - Preview

#Preview("With Orbs") {
    NavigationStack {
        OrbNebulaView()
            .environmentObject(RewardsManager.shared)
    }
}

#Preview("Empty") {
    NavigationStack {
        OrbNebulaView()
            .environmentObject(RewardsManager.shared)
    }
}
