import SwiftUI

/// Animated gradient orb that represents focus energy
/// Replaces the pixel art avatar with a modern, fluid visual element
struct GradientOrbView: View {
    let state: OrbState
    var size: CGFloat = 180

    @State private var breathingScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.6
    @State private var highlightOffset: CGFloat = 0
    @State private var celebrationScale: CGFloat = 1.0

    enum OrbState {
        case idle
        case focusing
        case onBreak
        case complete
    }

    var body: some View {
        ZStack {
            // Outer glow layer
            Circle()
                .fill(glowGradient)
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 25)
                .opacity(glowOpacity)

            // Main sphere body - base layer with radial gradient for 3D depth
            Circle()
                .fill(sphereGradient)
                .frame(width: size, height: size)

            // Secondary color layer for richness
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            secondaryColor.opacity(0.4),
                            secondaryColor.opacity(0.1),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.7, y: 0.7),
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)

            // Bottom shadow for grounding
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.8, height: size * 0.3)
                .offset(y: size * 0.45)
                .blur(radius: 8)

            // Rim light (subtle edge highlight)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.clear,
                            Color.clear,
                            primaryColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size - 2, height: size - 2)

            // Main specular highlight (top-left)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.25
                    )
                )
                .frame(width: size * 0.4, height: size * 0.4)
                .offset(x: -size * 0.2 + highlightOffset, y: -size * 0.2)
                .blur(radius: 3)

            // Secondary smaller highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.08
                    )
                )
                .frame(width: size * 0.15, height: size * 0.15)
                .offset(x: -size * 0.25, y: -size * 0.28)

            // Inner glow for energy effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            primaryColor.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.8, height: size * 0.8)
        }
        .scaleEffect(breathingScale * celebrationScale)
        .shadow(color: shadowColor.opacity(0.4), radius: 15, x: 0, y: 8)
        .onAppear {
            startBreathingAnimation()
        }
        .onChange(of: state) { newState in
            updateAnimations(for: newState)
        }
    }

    // MARK: - Colors

    private var primaryColor: Color {
        switch state {
        case .idle, .focusing:
            return Color.pomPrimary
        case .onBreak, .complete:
            return Color.pomSecondary
        }
    }

    private var secondaryColor: Color {
        switch state {
        case .idle:
            return Color.pomAccent
        case .focusing:
            return Color(hex: "FF8A80") // Pink
        case .onBreak:
            return Color(hex: "4ECDC4") // Teal
        case .complete:
            return Color(hex: "85E085") // Light green
        }
    }

    private var shadowColor: Color {
        switch state {
        case .idle, .focusing:
            return Color.pomPrimary
        case .onBreak, .complete:
            return Color.pomSecondary
        }
    }

    // MARK: - Gradients

    private var sphereGradient: RadialGradient {
        // Creates 3D sphere illusion with light from top-left
        RadialGradient(
            colors: [
                primaryColor.opacity(0.6),  // Lighter center-top
                primaryColor.opacity(0.85), // Mid tone
                primaryColor,               // Full color
                primaryColor.opacity(0.9),  // Slightly darker edge
            ],
            center: UnitPoint(x: 0.35, y: 0.35),
            startRadius: 0,
            endRadius: size * 0.6
        )
    }

    private var glowGradient: RadialGradient {
        RadialGradient(
            colors: [primaryColor.opacity(0.6), primaryColor.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: size * 0.7
        )
    }

    // MARK: - Animations

    private func startBreathingAnimation() {
        updateAnimations(for: state)
    }

    private func updateAnimations(for newState: OrbState) {
        // Reset celebration scale
        celebrationScale = 1.0

        switch newState {
        case .idle:
            // Gentle, calm breathing
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                breathingScale = 1.03
                glowOpacity = 0.5
                highlightOffset = 2
            }

        case .focusing:
            // Energized, faster pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                breathingScale = 1.05
                glowOpacity = 0.8
                highlightOffset = 4
            }

        case .onBreak:
            // Slow, relaxed rhythm
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                breathingScale = 1.02
                glowOpacity = 0.6
                highlightOffset = 1
            }

        case .complete:
            // Celebration burst
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                celebrationScale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    celebrationScale = 1.0
                }
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                breathingScale = 1.04
                glowOpacity = 0.9
                highlightOffset = 3
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        GradientOrbView(state: .idle, size: 150)
        GradientOrbView(state: .focusing, size: 150)
        GradientOrbView(state: .onBreak, size: 150)
    }
    .padding()
    .background(Color.pomBackground)
}
