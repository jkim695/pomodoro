import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    var lineWidth: CGFloat = 20
    var size: CGFloat = 280

    var body: some View {
        ZStack {
            // Track (background ring)
            Circle()
                .stroke(
                    Color.pomCream,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .shadow(color: Color.pomBrown.opacity(0.1), radius: 8, x: 0, y: 4)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    Color.pomSage,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
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
