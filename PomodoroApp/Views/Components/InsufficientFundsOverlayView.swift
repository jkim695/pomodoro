import SwiftUI

/// Overlay shown when user doesn't have enough Stardust to start a session
struct InsufficientFundsOverlayView: View {
    let required: Int
    let current: Int
    let onDismiss: () -> Void

    @State private var showContent = false

    private var shortfall: Int {
        required - current
    }

    private var stardustGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Content card
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(stardustGradient)
                    .opacity(0.5)

                Text("Not Enough Stardust")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.pomTextPrimary)

                Text("You need \(required) Stardust to start a session.\nYou currently have \(current).")
                    .font(.subheadline)
                    .foregroundColor(.pomTextSecondary)
                    .multilineTextAlignment(.center)

                // Shortfall display
                HStack(spacing: 4) {
                    Text("Need \(shortfall) more")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.pomAccent)
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(stardustGradient)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.pomAccentLight)
                )

                Spacer()
                    .frame(height: 8)

                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Text("OK")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.pomPrimary)
                        )
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.pomBackground)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showContent = true
            }
            // Haptic feedback for error
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
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
    InsufficientFundsOverlayView(
        required: 50,
        current: 23,
        onDismiss: { print("Dismissed") }
    )
}
