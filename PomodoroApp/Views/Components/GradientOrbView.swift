import SwiftUI

/// Animated gradient orb that represents focus energy
/// Replaces the pixel art avatar with a modern, fluid visual element
struct GradientOrbView: View {
    let state: OrbState
    var size: CGFloat = 180
    var style: OrbStyle? = nil  // Optional custom style override
    var starLevel: Int = 1  // Star level (1-5) affects glow, animation, particles

    @State private var breathingScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.6
    @State private var highlightOffset: CGFloat = 0
    @State private var celebrationScale: CGFloat = 1.0

    enum OrbState {
        case idle
        case focusing
        case complete
    }

    // MARK: - Star Level Multipliers

    /// Glow intensity multiplier based on star level (1.0 to 1.60)
    private var glowMultiplier: CGFloat {
        1.0 + (CGFloat(starLevel - 1) * 0.15)
    }

    /// Animation speed multiplier based on star level (1.0 to 1.40)
    private var animationSpeedMultiplier: Double {
        1.0 + (Double(starLevel - 1) * 0.1)
    }

    /// Number of orbiting particles (0 for 1-2 stars, 3/6/9 for 3/4/5 stars)
    private var particleCount: Int {
        starLevel >= 3 ? (starLevel - 2) * 3 : 0
    }

    var body: some View {
        ZStack {
            // Outer glow layer (enhanced by star level)
            Circle()
                .fill(glowGradient)
                .frame(width: size * 1.4 * glowMultiplier, height: size * 1.4 * glowMultiplier)
                .blur(radius: 25 * glowMultiplier)
                .opacity(glowOpacity * Double(glowMultiplier))

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

            // Star particles for 3+ star orbs
            if particleCount > 0 {
                StarParticlesView(
                    count: particleCount,
                    size: size,
                    color: primaryColor
                )
            }
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
        // Use custom style if provided (for idle/focusing states)
        if let style = style, state == .idle || state == .focusing {
            return style.primaryColor
        }
        // Default state-based colors
        switch state {
        case .idle, .focusing:
            return Color.pomPrimary
        case .complete:
            return Color.pomSecondary
        }
    }

    private var secondaryColor: Color {
        // Use custom style if provided (for idle/focusing states)
        if let style = style, state == .idle || state == .focusing {
            return style.secondaryColor
        }
        // Default state-based colors
        switch state {
        case .idle:
            return Color.pomAccent
        case .focusing:
            return Color(hex: "FF8A80") // Pink
        case .complete:
            return Color(hex: "85E085") // Light green
        }
    }

    private var shadowColor: Color {
        // Use custom style glow color if provided (for idle/focusing states)
        if let style = style, state == .idle || state == .focusing {
            return style.glowColor
        }
        // Default state-based colors
        switch state {
        case .idle, .focusing:
            return Color.pomPrimary
        case .complete:
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

        // Get animation properties from style if available
        let animStyle = style?.animationStyle
        let styleDuration = animStyle?.breathingDuration ?? 3.0
        let styleScale = animStyle?.scaleAmount ?? 1.03

        switch newState {
        case .idle:
            // Use style animation or default gentle, calm breathing
            // Apply star level speed multiplier
            let baseDuration = style != nil ? styleDuration : 3.0
            let duration = baseDuration / animationSpeedMultiplier
            let scale = style != nil ? styleScale : 1.03
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                breathingScale = scale
                glowOpacity = 0.5
                highlightOffset = 2
            }

        case .focusing:
            // Use style animation or default energized pulse
            // Apply star level speed multiplier
            let baseDuration = style != nil ? max(styleDuration * 0.5, 1.0) : 1.5
            let duration = baseDuration / animationSpeedMultiplier
            let scale = style != nil ? min(styleScale + 0.02, 1.08) : 1.05
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                breathingScale = scale
                glowOpacity = 0.8
                highlightOffset = 4
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
            let completeDuration = 2.0 / animationSpeedMultiplier
            withAnimation(.easeInOut(duration: completeDuration).repeatForever(autoreverses: true)) {
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
        GradientOrbView(state: .complete, size: 150)
    }
    .padding()
    .background(Color.pomBackground)
}
