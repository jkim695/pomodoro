import SwiftUI

struct CircularProgressView: View {
    let progress: Double  // 0 = just started, 1 = completed
    var lineWidth: CGFloat = 24
    var size: CGFloat = 280
    var animateFromProgress: Double? = nil  // Initial fill to animate from (for smooth session start)

    @State private var displayedProgress: CGFloat = 0
    @State private var hasAnimatedIn: Bool = false

    // Remaining progress (starts full, depletes to empty)
    private var remainingProgress: CGFloat {
        CGFloat(max(0, min(1, 1 - progress)))
    }

    var body: some View {
        ZStack {
            // Track (background ring) - subtle gray
            Circle()
                .stroke(
                    Color.pomBorder,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size - lineWidth, height: size - lineWidth)

            // Progress ring - shows remaining time (depletes as timer runs)
            Circle()
                .trim(from: 0, to: displayedProgress)
                .stroke(
                    Color.pomPrimary,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size - lineWidth, height: size - lineWidth)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .onAppear {
            if let initialProgress = animateFromProgress, !hasAnimatedIn {
                // Start from the slider's fill position for smooth transition
                displayedProgress = initialProgress
                hasAnimatedIn = true

                // Animate to full remaining progress
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        displayedProgress = remainingProgress
                    }
                }
            } else {
                displayedProgress = remainingProgress
            }
        }
        .onChange(of: remainingProgress) { newValue in
            // After initial animation, smoothly track progress changes
            if hasAnimatedIn {
                withAnimation(.linear(duration: 0.5)) {
                    displayedProgress = newValue
                }
            }
        }
    }
}

// MARK: - Binding Variant
struct CircularProgressBindingView: View {
    @Binding var progress: Double
    var lineWidth: CGFloat = 20
    var size: CGFloat = 280

    var body: some View {
        CircularProgressView(progress: progress, lineWidth: lineWidth, size: size)
    }
}

#Preview {
    VStack(spacing: 40) {
        CircularProgressView(progress: 0.3)
        CircularProgressView(progress: 0.7, lineWidth: 12, size: 150)
    }
    .padding()
    .background(Color.pomBackground)
}
