import SwiftUI
import Combine

/// A button that requires holding for 5 seconds before triggering the action.
/// Shows visual progress feedback and haptic milestones.
struct HoldToGiveUpButton: View {
    let onComplete: () -> Void

    // Hold configuration
    private let holdDuration: TimeInterval = 5.0
    private let updateInterval: TimeInterval = 0.05  // 20fps for smooth progress

    // State
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0  // 0.0 to 1.0
    @State private var timer: AnyCancellable?
    @State private var lastMilestone: Int = 0  // For haptic feedback at 25%, 50%, 75%

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (matching RoundedButton secondary style)
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.pomPrimaryLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.pomPrimary, lineWidth: 2)
                    )

                // Progress fill overlay
                if holdProgress > 0 {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.pomPrimary.opacity(0.3))
                        .mask(
                            GeometryReader { geo in
                                Rectangle()
                                    .frame(width: geo.size.width * holdProgress)
                            }
                        )
                }

                // Circular progress ring around button
                if isHolding {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pomPrimary, lineWidth: 4)
                        .opacity(0.5)
                }

                // Text content
                Text(buttonText)
                    .font(.pomButton)
                    .foregroundColor(.pomPrimary)
            }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
        .scaleEffect(isHolding ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHolding)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isHolding {
                        startHold()
                    }
                }
                .onEnded { _ in
                    endHold()
                }
        )
        .accessibilityLabel("Hold to give up")
        .accessibilityHint("Press and hold for 5 seconds to end session")
    }

    private var buttonText: String {
        if isHolding {
            let secondsRemaining = Int(ceil(holdDuration * (1 - holdProgress)))
            if secondsRemaining > 0 {
                return "Hold... \(secondsRemaining)s"
            } else {
                return "Releasing..."
            }
        }
        return "Hold to Give Up"
    }

    private func startHold() {
        isHolding = true
        holdProgress = 0
        lastMilestone = 0

        // Medium haptic at start
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Start progress timer
        let startTime = Date()
        timer = Timer.publish(every: updateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(1.0, elapsed / holdDuration)

                withAnimation(.linear(duration: updateInterval)) {
                    holdProgress = progress
                }

                // Haptic feedback at milestones (25%, 50%, 75%)
                let milestone = Int(progress * 4)
                if milestone > lastMilestone && milestone < 4 {
                    let lightFeedback = UIImpactFeedbackGenerator(style: .light)
                    lightFeedback.impactOccurred()
                    lastMilestone = milestone
                }

                // Complete when reaching 100%
                if progress >= 1.0 {
                    completeHold()
                }
            }
    }

    private func endHold() {
        guard isHolding else { return }

        // Cancel timer
        timer?.cancel()
        timer = nil

        // Reset if not completed
        if holdProgress < 1.0 {
            withAnimation(.easeOut(duration: 0.3)) {
                holdProgress = 0
            }
        }

        isHolding = false
        lastMilestone = 0
    }

    private func completeHold() {
        // Heavy haptic on completion
        let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
        heavyFeedback.impactOccurred()

        // Cancel timer
        timer?.cancel()
        timer = nil

        // Trigger action
        onComplete()

        // Reset state
        isHolding = false
        holdProgress = 0
        lastMilestone = 0
    }
}

#Preview {
    ZStack {
        Color.pomBackground
            .ignoresSafeArea()

        VStack(spacing: 40) {
            HoldToGiveUpButton {
                print("Give up triggered!")
            }

            Text("Hold the button for 5 seconds to give up")
                .font(.pomCaption)
                .foregroundColor(.pomTextTertiary)
        }
    }
}
