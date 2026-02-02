import SwiftUI

/// Enhanced celebration overlay showing earned Stardust and milestones
struct RewardCelebrationView: View {
    let earnedStardust: Int
    let milestones: [Milestone]
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var displayedStardust = 0
    @State private var showMilestones = false

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Content card
            VStack(spacing: 24) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.pomSecondary.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pomSecondary)
                        .scaleEffect(showContent ? 1 : 0.5)
                        .opacity(showContent ? 1 : 0)
                }

                // Title
                Text("Focus Complete!")
                    .font(.title.weight(.bold))
                    .foregroundColor(.pomTextPrimary)
                    .opacity(showContent ? 1 : 0)

                // Stardust earned
                VStack(spacing: 8) {
                    Text("You earned")
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

                        Text("+\(displayedStardust)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.pomTextPrimary)
                            .contentTransition(.numericText())
                    }

                    Text("Stardust")
                        .font(.subheadline)
                        .foregroundColor(.pomTextSecondary)
                }
                .opacity(showContent ? 1 : 0)

                // Milestones
                if !milestones.isEmpty {
                    VStack(spacing: 12) {
                        Text("Milestones Unlocked!")
                            .font(.headline)
                            .foregroundColor(.pomAccent)

                        ForEach(milestones) { milestone in
                            HStack(spacing: 12) {
                                Image(systemName: milestone.iconName)
                                    .font(.title3)
                                    .foregroundColor(.pomAccent)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(milestone.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.pomTextPrimary)

                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                            .font(.caption2)
                                        Text("+\(milestone.reward)")
                                            .font(.caption.weight(.medium))
                                    }
                                    .foregroundColor(Color(hex: "FFD700"))
                                }

                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.pomCardBackground)
                            )
                        }
                    }
                    .opacity(showMilestones ? 1 : 0)
                    .offset(y: showMilestones ? 0 : 20)
                }

                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.pomPrimary)
                        )
                }
                .opacity(showContent ? 1 : 0)
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.pomBackground)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
            .scaleEffect(showContent ? 1 : 0.8)
        }
        .onAppear {
            animateIn()
        }
    }

    private func animateIn() {
        // Show content with spring animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showContent = true
        }

        // Count up stardust
        animateStardustCount()

        // Show milestones after stardust animation
        if !milestones.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showMilestones = true
                }
            }
        }

        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func animateStardustCount() {
        let duration: Double = 0.8
        let steps = min(earnedStardust, 30)
        let interval = duration / Double(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                let progress = Double(i + 1) / Double(steps)
                displayedStardust = Int(Double(earnedStardust) * progress)

                // Light haptic on each count
                if i % 3 == 0 {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }

        // Ensure final value is exact
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            displayedStardust = earnedStardust
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

#Preview {
    RewardCelebrationView(
        earnedStardust: 15,
        milestones: [Milestones.all[0], Milestones.all[1]]
    ) { }
}
