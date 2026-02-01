import SwiftUI

// MARK: - Animation Definitions
extension Animation {
    // Gentle pulse for running timer
    static let pulse = Animation
        .easeInOut(duration: 1.0)
        .repeatForever(autoreverses: true)

    // Button press feedback
    static let buttonPress = Animation.spring(response: 0.25, dampingFraction: 0.7)

    // State transitions
    static let stateTransition = Animation.spring(response: 0.5, dampingFraction: 0.7)

    // Celebration bounce
    static let celebration = Animation.spring(response: 0.4, dampingFraction: 0.6)

    // Orb animations
    static let orbBreathing = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
    static let orbPulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)

    // Shield/Limits animations
    static let shieldBreathing = Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)
    static let cardActivePulse = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
    static let warningPulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
}

// MARK: - View Modifiers for Animations

struct PulseModifier: ViewModifier {
    let isActive: Bool
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: isActive) { newValue in
                if newValue {
                    withAnimation(.pulse) {
                        scale = 1.02
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        scale = 1.0
                    }
                }
            }
            .onAppear {
                if isActive {
                    withAnimation(.pulse) {
                        scale = 1.02
                    }
                }
            }
    }
}

struct ButtonPressModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.buttonPress, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

struct CelebrationModifier: ViewModifier {
    let isActive: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? scale : 0.5)
            .opacity(isActive ? opacity : 0)
            .onChange(of: isActive) { newValue in
                if newValue {
                    withAnimation(.celebration) {
                        scale = 1.0
                        opacity = 1.0
                    }
                } else {
                    scale = 0.5
                    opacity = 0
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func pulseAnimation(isActive: Bool) -> some View {
        modifier(PulseModifier(isActive: isActive))
    }

    func buttonPressAnimation() -> some View {
        modifier(ButtonPressModifier())
    }

    func celebrationAnimation(isActive: Bool) -> some View {
        modifier(CelebrationModifier(isActive: isActive))
    }
}
