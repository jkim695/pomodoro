import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    var lineWidth: CGFloat = 24
    var size: CGFloat = 280
    var isFocusing: Bool = true  // Controls color scheme

    var body: some View {
        ZStack {
            // Track (background ring) - subtle gray
            Circle()
                .stroke(
                    Color.pomBorder,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
                .shadow(color: progressColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .frame(width: size, height: size)
    }

    private var progressColor: Color {
        isFocusing ? Color.pomPrimary : Color.pomSecondary
    }

    private var progressGradient: LinearGradient {
        if isFocusing {
            return LinearGradient(
                colors: [Color.pomPrimary, Color.pomAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.pomSecondary, Color(hex: "4ECDC4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Binding Variant
struct CircularProgressBindingView: View {
    @Binding var progress: Double
    var lineWidth: CGFloat = 20
    var size: CGFloat = 280
    var isFocusing: Bool = true

    var body: some View {
        CircularProgressView(progress: progress, lineWidth: lineWidth, size: size, isFocusing: isFocusing)
    }
}

#Preview {
    VStack(spacing: 40) {
        CircularProgressView(progress: 0.3, isFocusing: true)
        CircularProgressView(progress: 0.7, lineWidth: 12, size: 150, isFocusing: false)
    }
    .padding()
    .background(Color.pomBackground)
}
