import SwiftUI

/// Enhanced progress bar with glow effects for the Limits feature
/// Shows usage progress with color-coded states and optional glow
struct GlowingProgressBar: View {
    let progress: Double  // 0.0 to 1.0+
    var showGlow: Bool = true
    var height: CGFloat = 8

    @State private var warningPulse: Double = 1.0

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return .pomDestructive
        } else if progress >= 0.75 {
            return .pomAccent
        } else {
            return .pomSecondary
        }
    }

    private var shouldPulse: Bool {
        progress >= 0.75 && progress < 1.0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.pomBorder.opacity(0.5))
                    .frame(height: height)

                // Glow layer (beneath the bar)
                if showGlow && clampedProgress > 0 {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(progressColor.opacity(0.4))
                        .frame(width: geometry.size.width * clampedProgress, height: height)
                        .blur(radius: 6)
                        .opacity(warningPulse)
                }

                // Progress fill with gradient
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                progressColor.opacity(0.8),
                                progressColor
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * clampedProgress, height: height)
                    .shadow(color: progressColor.opacity(showGlow ? 0.5 : 0), radius: 4, x: 0, y: 0)
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.3), value: progress)
        .onAppear {
            if shouldPulse {
                startWarningPulse()
            }
        }
        .onChange(of: shouldPulse) { newValue in
            if newValue {
                startWarningPulse()
            } else {
                stopWarningPulse()
            }
        }
    }

    private func startWarningPulse() {
        withAnimation(.warningPulse) {
            warningPulse = 0.5
        }
    }

    private func stopWarningPulse() {
        withAnimation(.easeOut(duration: 0.2)) {
            warningPulse = 1.0
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
            Text("25% - Safe").font(.caption)
            GlowingProgressBar(progress: 0.25)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("50% - Normal").font(.caption)
            GlowingProgressBar(progress: 0.50)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("75% - Warning").font(.caption)
            GlowingProgressBar(progress: 0.75)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("90% - Critical").font(.caption)
            GlowingProgressBar(progress: 0.90)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("100% - Exceeded").font(.caption)
            GlowingProgressBar(progress: 1.0)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("No glow").font(.caption)
            GlowingProgressBar(progress: 0.6, showGlow: false)
        }
    }
    .padding(24)
    .background(Color.pomBackground)
}
