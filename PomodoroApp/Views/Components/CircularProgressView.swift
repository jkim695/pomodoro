import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    var lineWidth: CGFloat = 32  // CHUNKY ring for kawaii aesthetic
    var size: CGFloat = 280

    var body: some View {
        ZStack {
            // Track (background ring) - warm beige for kawaii aesthetic with depth
            Circle()
                .stroke(
                    Color.pomLightBrown.opacity(0.2),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                // Inner shadow effect for depth
                .overlay(
                    Circle()
                        .stroke(
                            Color.pomBrown.opacity(0.08),
                            style: StrokeStyle(lineWidth: lineWidth - 4, lineCap: .round)
                        )
                        .blur(radius: 2)
                        .offset(x: 1, y: 2)
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    Color.pomSage,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
                .shadow(color: Color.pomSage.opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .frame(width: size, height: size)
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
    .background(Color.pomCream)
}
