import SwiftUI

/// A circular slider for selecting focus duration
/// Full 360-degree circle starting from top (12 o'clock), fills clockwise
struct CircularDurationSlider: View {
    @Binding var duration: Int  // Duration in minutes (10-180)
    var size: CGFloat = 340
    var trackWidth: CGFloat = 20
    var isEnabled: Bool = true
    var accentColor: Color = .pomPrimary  // Customizable ring and thumb color

    // Internal state
    @State private var isDragging: Bool = false
    @State private var visualAngle: CGFloat = 0  // Smooth visual angle (0 to 2π)
    @State private var previousAngle: CGFloat? = nil
    @State private var lastHapticValue: Int = 0

    // Constants
    private let minDuration: Int = 10
    private let maxDuration: Int = 180
    private let stepSize: Int = 5
    private let minDisplayAngle: CGFloat = 20 / 360  // 20 degrees minimum arc at lowest duration

    // Radius for the track center
    private var radius: CGFloat {
        (size - trackWidth) / 2
    }

    // Progress for display (minDisplayAngle to 1)
    // When dragging: use smooth visual angle
    // When not dragging: use snapped duration
    // Always shows at least minDisplayAngle (20 degrees) even at minimum duration
    private var displayProgress: CGFloat {
        let rawProgress: CGFloat
        if isDragging {
            rawProgress = visualAngle / (2 * .pi)
        } else {
            rawProgress = CGFloat(duration - minDuration) / CGFloat(maxDuration - minDuration)
        }
        // Scale progress to leave room for minimum angle
        return minDisplayAngle + (rawProgress * (1 - minDisplayAngle))
    }

    var body: some View {
        ZStack {
            // Background track (full circle)
            Circle()
                .stroke(
                    Color.pomBorder,
                    style: StrokeStyle(lineWidth: trackWidth, lineCap: .round)
                )
                .frame(width: size - trackWidth, height: size - trackWidth)

            // Filled arc showing selected duration
            Circle()
                .trim(from: 0, to: displayProgress)
                .stroke(
                    accentColor,
                    style: StrokeStyle(lineWidth: trackWidth, lineCap: .round)
                )
                .frame(width: size - trackWidth, height: size - trackWidth)
                .rotationEffect(.degrees(-90)) // Start from top (12 o'clock)

            // Thumb/knob at current position
            Circle()
                .fill(accentColor)
                .frame(width: 20, height: 20)
                .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
                .offset(thumbOffset)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard isEnabled else { return }
                    handleDrag(at: value.location)
                }
                .onEnded { _ in
                    endDrag()
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus duration")
        .accessibilityValue("\(duration) minutes")
        .accessibilityHint("Drag around the circle to adjust duration")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                duration = min(maxDuration, duration + stepSize)
            case .decrement:
                duration = max(minDuration, duration - stepSize)
            @unknown default:
                break
            }
        }
    }

    // MARK: - Thumb Position

    /// Offset for thumb position from center
    private var thumbOffset: CGSize {
        // Convert display progress to angle: 0 progress = top, 1 progress = full circle
        let angle = (displayProgress * 2 * .pi) - (.pi / 2)

        return CGSize(
            width: radius * cos(angle),
            height: radius * sin(angle)
        )
    }

    // MARK: - Gesture Handling

    /// Calculate angle from touch location (0 = top, increases clockwise, 0 to 2π)
    private func angleFromLocation(_ location: CGPoint) -> CGFloat {
        let localCenter = CGPoint(x: size / 2, y: size / 2)
        let dx = location.x - localCenter.x
        let dy = location.y - localCenter.y

        var angle = atan2(dy, dx) + (.pi / 2)
        if angle < 0 {
            angle += 2 * .pi
        }
        return angle
    }

    /// Current angle based on duration (0 to 2π)
    private var currentAngle: CGFloat {
        CGFloat(duration - minDuration) / CGFloat(maxDuration - minDuration) * 2 * .pi
    }

    private func handleDrag(at location: CGPoint) {
        let localCenter = CGPoint(x: size / 2, y: size / 2)

        // Check if touch is near the track
        let distance = hypot(location.x - localCenter.x, location.y - localCenter.y)
        let innerRadius = radius - trackWidth
        let outerRadius = radius + trackWidth

        // Only start drag if near the track
        if !isDragging && (distance < innerRadius || distance > outerRadius) {
            return
        }

        let touchAngle = angleFromLocation(location)

        if !isDragging {
            // Starting a new drag - check if touch would cause a large jump
            let angleDiff = abs(touchAngle - currentAngle)
            let normalizedDiff = min(angleDiff, 2 * .pi - angleDiff)

            // If touch is more than 90 degrees away from current position, don't jump
            // Instead, start from current position
            if normalizedDiff > .pi / 2 {
                isDragging = true
                lastHapticValue = duration
                visualAngle = currentAngle
                previousAngle = currentAngle
                return
            }

            isDragging = true
            lastHapticValue = duration
            visualAngle = currentAngle
            previousAngle = currentAngle
        }

        var angle = touchAngle

        // Prevent wrap-around: if we're near the ends and make a big jump, clamp
        if let prev = previousAngle {
            let delta = angle - prev

            // If jumping more than π radians, we're wrapping around
            if delta > .pi {
                // Jumped from high to low - clamp to min
                angle = 0
            } else if delta < -.pi {
                // Jumped from low to high - clamp to max
                angle = 2 * .pi - 0.001
            }
        }

        previousAngle = angle

        // Update visual angle smoothly
        visualAngle = angle

        // Convert angle to duration for snapping check
        let progress = angle / (2 * .pi)
        let range = Double(maxDuration - minDuration)
        let rawDuration = Double(minDuration) + (Double(progress) * range)

        // Snap to step increments
        let snappedDuration = (Int(rawDuration.rounded()) / stepSize) * stepSize
        let newDuration = max(minDuration, min(maxDuration, snappedDuration))

        // Only update duration and trigger haptic when crossing step boundaries
        if newDuration != lastHapticValue {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            lastHapticValue = newDuration
            duration = newDuration
        }
    }

    private func endDrag() {
        if isDragging {
            isDragging = false
            previousAngle = nil
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
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
                    CircularDurationSlider(duration: $duration)

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
