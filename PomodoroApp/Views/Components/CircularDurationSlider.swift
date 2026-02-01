import SwiftUI

/// A circular slider for selecting focus duration
/// Wraps around the timer circle and allows drag-to-select duration
struct CircularDurationSlider: View {
    @Binding var duration: Int  // Duration in minutes (10-180)
    var size: CGFloat = 340
    var trackWidth: CGFloat = 44
    var isEnabled: Bool = true

    // Internal state
    @State private var isDragging: Bool = false
    @State private var lastHapticValue: Int = 0

    // Constants
    private let minDuration: Int = 10
    private let maxDuration: Int = 180
    private let stepSize: Int = 5

    // Arc configuration - use 270 degrees (3/4 circle) to avoid wrap-around
    private let startAngle: Double = 135  // degrees from top (starts at bottom-left)
    private let totalArcAngle: Double = 270  // degrees of arc

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = (size - trackWidth) / 2

            ZStack {
                // Background track
                Circle()
                    .trim(from: 0, to: totalArcAngle / 360)
                    .stroke(
                        Color.pomBorder.opacity(0.4),
                        style: StrokeStyle(lineWidth: trackWidth - 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(startAngle - 90))

                // Filled arc showing selected duration
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        LinearGradient(
                            colors: [Color.pomPrimary.opacity(0.6), Color.pomAccent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: trackWidth - 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(startAngle - 90))
                    .shadow(color: Color.pomPrimary.opacity(0.2), radius: 4, x: 0, y: 2)

                // Knob at current position
                Circle()
                    .fill(Color.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .stroke(Color.pomPrimary, lineWidth: 3)
                    )
                    .position(knobPosition(center: center, radius: radius))
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDragging)

                // Duration tooltip when dragging
                if isDragging {
                    durationTooltip
                        .position(x: center.x, y: center.y - size / 2 + 30)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isEnabled else { return }
                        handleDrag(at: value.location, center: center, radius: radius)
                    }
                    .onEnded { _ in
                        endDrag()
                    }
            )
        }
        .frame(width: size, height: size)
    }

    // MARK: - Computed Properties

    /// Progress value for the arc (0 to totalArcAngle/360)
    private var progressValue: CGFloat {
        let range = Double(maxDuration - minDuration)
        let progress = Double(duration - minDuration) / range
        return CGFloat(progress * totalArcAngle / 360)
    }

    /// Calculate knob position on the arc
    private func knobPosition(center: CGPoint, radius: CGFloat) -> CGPoint {
        let range = Double(maxDuration - minDuration)
        let progress = Double(duration - minDuration) / range
        let angleInDegrees = startAngle + (progress * totalArcAngle)
        let angleInRadians = angleInDegrees * .pi / 180

        return CGPoint(
            x: center.x + radius * CGFloat(cos(angleInRadians)),
            y: center.y + radius * CGFloat(sin(angleInRadians))
        )
    }

    // MARK: - Gesture Handling

    private func handleDrag(at location: CGPoint, center: CGPoint, radius: CGFloat) {
        // Check if touch is near the track
        let distance = hypot(location.x - center.x, location.y - center.y)
        let innerRadius = radius - trackWidth / 2
        let outerRadius = radius + trackWidth / 2

        // Allow starting drag from anywhere, but only process if reasonably close to track
        if !isDragging && (distance < innerRadius - 20 || distance > outerRadius + 20) {
            return
        }

        if !isDragging {
            isDragging = true
            lastHapticValue = duration
        }

        // Calculate angle from touch position
        let dx = location.x - center.x
        let dy = location.y - center.y
        var angleInDegrees = atan2(dy, dx) * 180 / .pi

        // Convert to our coordinate system (startAngle is 0 progress)
        angleInDegrees -= startAngle
        if angleInDegrees < 0 {
            angleInDegrees += 360
        }

        // Clamp to arc range
        let clampedAngle = max(0, min(totalArcAngle, angleInDegrees))

        // Convert angle to duration
        let progress = clampedAngle / totalArcAngle
        let range = Double(maxDuration - minDuration)
        let rawDuration = Double(minDuration) + (progress * range)

        // Snap to 5-minute increments
        let snappedDuration = (Int(rawDuration.rounded()) / stepSize) * stepSize
        let newDuration = max(minDuration, min(maxDuration, snappedDuration))

        // Trigger haptic when crossing 5-minute boundaries
        if newDuration != lastHapticValue {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            lastHapticValue = newDuration
        }

        duration = newDuration
    }

    private func endDrag() {
        if isDragging {
            isDragging = false
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }

    // MARK: - Subviews

    private var durationTooltip: some View {
        Text(formatDuration(duration))
            .font(.pomBody)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.pomPrimary)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var duration: Int = 25

        var body: some View {
            ZStack {
                Color.pomBackground
                    .ignoresSafeArea()

                VStack {
                    ZStack {
                        CircularDurationSlider(duration: $duration)

                        // Simulated timer circle
                        Circle()
                            .stroke(Color.pomBorder, lineWidth: 20)
                            .frame(width: 280, height: 280)

                        Text("\(duration)m")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.pomTextPrimary)
                    }

                    Text("Duration: \(duration) minutes")
                        .font(.pomBody)
                        .foregroundColor(.pomTextSecondary)
                        .padding(.top, 40)
                }
            }
        }
    }

    return PreviewWrapper()
}
