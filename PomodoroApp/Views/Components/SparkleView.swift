import SwiftUI
import Foundation

struct SparkleView: View {
    let size: CGFloat
    @State private var sparkles: [Sparkle] = []

    private let sparkleColors: [Color] = [
        .pomPeach,
        .pomSage,
        Color(hex: "FFD700"), // Gold
        .white
    ]

    struct Sparkle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var scale: CGFloat
        var opacity: Double
        var rotation: Double
        let color: Color
    }

    var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                SparkleShape()
                    .fill(sparkle.color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(sparkle.scale)
                    .opacity(sparkle.opacity)
                    .rotationEffect(.degrees(sparkle.rotation))
                    .position(sparkle.position)
            }
        }
        .frame(width: size * 1.5, height: size)
        .onAppear {
            startSparkleAnimation()
        }
    }

    private func startSparkleAnimation() {
        // Generate initial sparkles
        for _ in 0..<8 {
            addSparkle()
        }

        // Continue adding sparkles
        Task {
            while true {
                try? await Task.sleep(for: .milliseconds(200))
                await MainActor.run {
                    addSparkle()
                    cleanupSparkles()
                }
            }
        }
    }

    private func addSparkle() {
        let centerX = size * 0.75
        let centerY = size * 0.5

        let angle = Double.random(in: 0...(2 * Double.pi))
        let distance = Double(size * 0.6) * Double.random(in: 0.3...1.0)

        let x = Double(centerX) + cos(angle) * distance
        let y = Double(centerY) + sin(angle) * distance

        let sparkle = Sparkle(
            position: CGPoint(x: x, y: y),
            scale: 0.1,
            opacity: 0,
            rotation: Double.random(in: 0...360),
            color: sparkleColors.randomElement() ?? .white
        )

        sparkles.append(sparkle)
        let index = sparkles.count - 1

        // Animate in
        withAnimation(.easeOut(duration: 0.3)) {
            sparkles[index].scale = CGFloat.random(in: 0.8...1.2)
            sparkles[index].opacity = 1.0
        }

        // Animate out
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            await MainActor.run {
                if index < sparkles.count {
                    withAnimation(.easeIn(duration: 0.4)) {
                        sparkles[index].scale = 0.1
                        sparkles[index].opacity = 0
                        sparkles[index].rotation += 180
                    }
                }
            }
        }
    }

    private func cleanupSparkles() {
        sparkles.removeAll { $0.opacity == 0 && $0.scale < 0.2 }
        // Keep max 15 sparkles
        if sparkles.count > 15 {
            sparkles.removeFirst(sparkles.count - 15)
        }
    }
}

struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = Double(min(rect.width, rect.height) / 2)
        let innerRadius = outerRadius * 0.4

        for i in 0..<4 {
            let angle = Double(i) * Double.pi / 2 - Double.pi / 2
            let outerPoint = CGPoint(
                x: Double(center.x) + cos(angle) * outerRadius,
                y: Double(center.y) + sin(angle) * outerRadius
            )

            let innerAngle1 = angle - Double.pi / 4
            let innerAngle2 = angle + Double.pi / 4

            let innerPoint1 = CGPoint(
                x: Double(center.x) + cos(innerAngle1) * innerRadius,
                y: Double(center.y) + sin(innerAngle1) * innerRadius
            )
            let innerPoint2 = CGPoint(
                x: Double(center.x) + cos(innerAngle2) * innerRadius,
                y: Double(center.y) + sin(innerAngle2) * innerRadius
            )

            if i == 0 {
                path.move(to: outerPoint)
            } else {
                path.addLine(to: outerPoint)
            }
            path.addLine(to: innerPoint2)
        }

        // Complete the star
        let finalInnerAngle = -3 * Double.pi / 4
        let finalInnerPoint = CGPoint(
            x: Double(center.x) + cos(finalInnerAngle) * innerRadius,
            y: Double(center.y) + sin(finalInnerAngle) * innerRadius
        )
        path.addLine(to: finalInnerPoint)
        path.closeSubpath()

        return path
    }
}

#Preview {
    ZStack {
        Color.pomCream
        SparkleView(size: 150)
    }
}
