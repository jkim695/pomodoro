import SwiftUI

struct AnimatedTimerText: View {
    let timeRemaining: Int
    let isRunning: Bool

    @State private var scale: CGFloat = 1.0

    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        Text(formattedTime)
            .font(.timerDisplay)
            .foregroundColor(.pomBrown)
            .monospacedDigit()
            .scaleEffect(scale)
            .onChange(of: isRunning) { running in
                if running {
                    startPulse()
                } else {
                    stopPulse()
                }
            }
            .onAppear {
                if isRunning {
                    startPulse()
                }
            }
    }

    private func startPulse() {
        withAnimation(
            Animation
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
        ) {
            scale = 1.02
        }
    }

    private func stopPulse() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 1.0
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        AnimatedTimerText(timeRemaining: 1500, isRunning: false)
        AnimatedTimerText(timeRemaining: 300, isRunning: true)
    }
    .padding()
    .background(Color.pomCream)
}
