import SwiftUI

/// Animated orbiting sparkle particles for high-star orbs (3+ stars)
struct StarParticlesView: View {
    let count: Int
    let size: CGFloat
    let color: Color

    @State private var rotation1: Double = 0
    @State private var rotation2: Double = 0
    @State private var rotation3: Double = 0

    var body: some View {
        ZStack {
            // Orbital plane 1: Horizontal
            OrbitalPlane(
                particleCount: max(1, count / 3),
                size: size,
                color: color,
                yScale: 1.0,
                angleOffset: 0
            )
            .rotationEffect(.degrees(rotation1))

            // Orbital plane 2: Tilted (elliptical)
            OrbitalPlane(
                particleCount: max(1, count / 3),
                size: size,
                color: color,
                yScale: 0.4,
                angleOffset: 40
            )
            .rotationEffect(.degrees(rotation2))

            // Orbital plane 3: Tilted opposite (elliptical)
            OrbitalPlane(
                particleCount: max(1, count / 3),
                size: size,
                color: color,
                yScale: 0.4,
                angleOffset: 80
            )
            .rotation3DEffect(.degrees(90), axis: (x: 0, y: 1, z: 0))
            .rotationEffect(.degrees(rotation3))
        }
        .onAppear {
            // 1/5 the speed = 5x the duration (8s -> 40s)
            withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
                rotation1 = 360
            }
            withAnimation(.linear(duration: 48).repeatForever(autoreverses: false)) {
                rotation2 = -360  // Opposite direction
            }
            withAnimation(.linear(duration: 52).repeatForever(autoreverses: false)) {
                rotation3 = 360
            }
        }
    }
}

/// A single orbital plane containing multiple particles
private struct OrbitalPlane: View {
    let particleCount: Int
    let size: CGFloat
    let color: Color
    let yScale: CGFloat
    let angleOffset: Double

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                let angle = Double(index) * (360.0 / Double(particleCount)) + angleOffset
                StarSparkle(
                    size: CGFloat.random(in: 4...8),
                    color: color
                )
                .offset(
                    x: cos(angle * .pi / 180) * size * 0.6,
                    y: sin(angle * .pi / 180) * size * 0.6 * yScale
                )
            }
        }
    }
}

/// Individual sparkle that twinkles but doesn't rotate
private struct StarSparkle: View {
    let size: CGFloat
    let color: Color

    @State private var opacity: Double = 0.6
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundStyle(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
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
