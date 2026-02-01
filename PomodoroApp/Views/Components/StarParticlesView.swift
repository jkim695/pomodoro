import SwiftUI

/// Animated orbiting sparkle particles for high-star orbs (3+ stars)
struct StarParticlesView: View {
    let count: Int
    let size: CGFloat
    let color: Color

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                StarParticle(
                    particleSize: CGFloat.random(in: 4...8),
                    color: color,
                    angle: Double(index) * (360.0 / Double(count)),
                    radius: size * 0.6
                )
            }
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

/// Individual orbiting particle
private struct StarParticle: View {
    let particleSize: CGFloat
    let color: Color
    let angle: Double
    let radius: CGFloat

    @State private var opacity: Double = 0.6
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: particleSize))
            .foregroundStyle(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(
                x: cos(angle * .pi / 180) * radius,
                y: sin(angle * .pi / 180) * radius
            )
            .onAppear {
                // Subtle twinkle animation
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1.0...2.0))
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...1))
                ) {
                    opacity = 1.0
                    scale = 1.2
                }
            }
    }
}

#Preview {
    VStack(spacing: 40) {
        ZStack {
            Circle()
                .fill(Color.pomPrimary)
                .frame(width: 100, height: 100)
            StarParticlesView(count: 3, size: 100, color: .pomPrimary)
        }

        ZStack {
            Circle()
                .fill(Color.purple)
                .frame(width: 100, height: 100)
            StarParticlesView(count: 6, size: 100, color: .purple)
        }

        ZStack {
            Circle()
                .fill(Color.orange)
                .frame(width: 100, height: 100)
            StarParticlesView(count: 9, size: 100, color: .orange)
        }
    }
    .padding()
    .background(Color.pomBackground)
}
