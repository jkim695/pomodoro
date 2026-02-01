import SwiftUI

/// Overlay shown during quit cool-down period
struct CoolDownOverlayView: View {
    let timeRemaining: Int
    let anteAmount: Int
    let onResume: () -> Void
    let onConfirmQuit: () -> Void

    @State private var showContent = false

    private var canConfirmQuit: Bool {
        timeRemaining == 0
    }

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

                if !canConfirmQuit {
                    Text("If you still want to quit in \(timeRemaining) second\(timeRemaining == 1 ? "" : "s"), the button will unlock.")
                        .font(.subheadline)
                        .foregroundColor(.pomTextSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("You can now confirm your choice.")
                        .font(.subheadline)
                        .foregroundColor(.pomTextSecondary)
                        .multilineTextAlignment(.center)
                }

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

                    // Confirm quit button (disabled during countdown)
                    Button {
                        if canConfirmQuit {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            onConfirmQuit()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if !canConfirmQuit {
                                // Show countdown
                                Text("\(timeRemaining)")
                                    .font(.headline.monospacedDigit())
                                    .foregroundColor(.pomTextTertiary)
                                    .frame(width: 24)
                            }
                            Text("Confirm Quit")
                        }
                        .font(.headline)
                        .foregroundColor(canConfirmQuit ? .white : .pomTextTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canConfirmQuit ? Color.pomDestructive : Color.pomCardBackgroundAlt)
                        )
                    }
                    .disabled(!canConfirmQuit)
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
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

#Preview {
    CoolDownOverlayView(
        timeRemaining: 7,
        anteAmount: 50,
        onResume: { print("Resume") },
        onConfirmQuit: { print("Quit") }
    )
}
