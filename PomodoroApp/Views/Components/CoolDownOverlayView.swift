import SwiftUI
import Combine

/// Overlay shown during quit cool-down period
struct CoolDownOverlayView: View {
    let anteAmount: Int
    let onResume: () -> Void
    let onConfirmQuit: () -> Void

    @State private var showContent = false

    // Hold-to-confirm state
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var timer: AnyCancellable?
    @State private var lastMilestone: Int = 0

    private let holdDuration: TimeInterval = 5.0
    private let updateInterval: TimeInterval = 0.05

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Content card
            VStack(spacing: 24) {
                // Breathing icon with pulse animation
                Image(systemName: "wind")
                    .font(.system(size: 48))
                    .foregroundColor(.pomAccent)
                    .opacity(showContent ? 1 : 0.6)
                    .scaleEffect(showContent ? 1.05 : 0.95)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: showContent
                    )

                // Message
                Text("Take a breath.")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.pomTextPrimary)

                Text("Hold the button below for 5 seconds to confirm quitting.")
                    .font(.subheadline)
                    .foregroundColor(.pomTextSecondary)
                    .multilineTextAlignment(.center)

                // Warning about ante loss
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.pomAccent)
                    Text("You will lose \(anteAmount) Stardust")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.pomAccent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.pomAccentLight)
                )

                Spacer()
                    .frame(height: 8)

                // Buttons
                VStack(spacing: 12) {
                    // Resume button (always enabled)
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onResume()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Resume Session")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.pomSecondary)
                        )
                    }

                    // Hold-to-confirm quit button
                    holdToConfirmButton
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.pomBackground)
                    .shadow(color: .black.opacity(0.3), radius: 20)
            )
            .padding(.horizontal, 24)
            .scaleEffect(showContent ? 1 : 0.9)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showContent = true
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    // MARK: - Hold to Confirm Button

    private var holdToConfirmButton: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pomCardBackgroundAlt)

            // Progress fill
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pomDestructive.opacity(0.7))
                    .frame(width: geo.size.width * holdProgress)
            }

            // Border when holding
            if isHolding {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pomDestructive, lineWidth: 2)
            }

            // Text
            Text(holdButtonText)
                .font(.headline)
                .foregroundColor(isHolding ? .white : .pomTextSecondary)
        }
        .frame(height: 52)
        .frame(maxWidth: .infinity)
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
    }

    private var holdButtonText: String {
        if isHolding {
            let secondsRemaining = Int(ceil(holdDuration * (1 - holdProgress)))
            if secondsRemaining > 0 {
                return "Hold... \(secondsRemaining)s"
            } else {
                return "Quitting..."
            }
        }
        return "Hold to Confirm Quit"
    }

    private func startHold() {
        isHolding = true
        holdProgress = 0
        lastMilestone = 0

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let startTime = Date()
        timer = Timer.publish(every: updateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(1.0, elapsed / holdDuration)

                withAnimation(.linear(duration: updateInterval)) {
                    holdProgress = progress
                }

                // Haptic at milestones
                let milestone = Int(progress * 4)
                if milestone > lastMilestone && milestone < 4 {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    lastMilestone = milestone
                }

                if progress >= 1.0 {
                    completeHold()
                }
            }
    }

    private func endHold() {
        guard isHolding else { return }

        timer?.cancel()
        timer = nil

        if holdProgress < 1.0 {
            withAnimation(.easeOut(duration: 0.3)) {
                holdProgress = 0
            }
        }

        isHolding = false
        lastMilestone = 0
    }

    private func completeHold() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        timer?.cancel()
        timer = nil

        onConfirmQuit()

        isHolding = false
        holdProgress = 0
        lastMilestone = 0
    }
}

#Preview {
    CoolDownOverlayView(
        anteAmount: 50,
        onResume: { print("Resume") },
        onConfirmQuit: { print("Quit") }
    )
}
