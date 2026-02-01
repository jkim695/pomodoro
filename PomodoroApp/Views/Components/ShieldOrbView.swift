import SwiftUI

/// Shield-themed orb for the Limits feature
/// Shows cyan glow when active (protecting from distractions)
struct ShieldOrbView: View {
    let isActive: Bool
    var size: CGFloat = 60

    @State private var breathingScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.5

    private var primaryColor: Color {
        isActive ? .pomShieldActive : .pomShieldInactive
    }

    private var secondaryColor: Color {
        isActive ? Color(hex: "0099CC") : Color(hex: "3A3A3A")
    }

    var body: some View {
        ZStack {
            // Outer glow layer (only when active)
            if isActive {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [primaryColor.opacity(0.5), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.7
                        )
                    )
                    .frame(width: size * 1.4, height: size * 1.4)
                    .blur(radius: 15)
                    .opacity(glowOpacity)
            }

            // Main sphere body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            primaryColor.opacity(0.6),
                            primaryColor.opacity(0.85),
                            primaryColor,
                            primaryColor.opacity(0.9)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size, height: size)

            // Secondary color layer
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

            // Rim light
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isActive ? 0.5 : 0.2),
                            Color.clear,
                            Color.clear,
                            primaryColor.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: size - 1.5, height: size - 1.5)

            // Main specular highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(isActive ? 0.9 : 0.5),
                            Color.white.opacity(isActive ? 0.4 : 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.2
                    )
                )
                .frame(width: size * 0.35, height: size * 0.35)
                .offset(x: -size * 0.18, y: -size * 0.18)
                .blur(radius: 2)

            // Secondary highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(isActive ? 0.6 : 0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.06
                    )
                )
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: -size * 0.22, y: -size * 0.25)

            // Shield icon overlay (subtle)
            Image(systemName: "shield.fill")
                .font(.system(size: size * 0.35, weight: .medium))
                .foregroundColor(.white.opacity(isActive ? 0.3 : 0.15))
        }
        .scaleEffect(breathingScale)
        .shadow(color: primaryColor.opacity(isActive ? 0.4 : 0.1), radius: 10, x: 0, y: 4)
        .onAppear {
            if isActive {
                startBreathingAnimation()
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                startBreathingAnimation()
            } else {
                stopBreathingAnimation()
            }
        }
    }

    private func startBreathingAnimation() {
        withAnimation(.shieldBreathing) {
            breathingScale = 1.03
            glowOpacity = 0.7
        }
    }

    private func stopBreathingAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            breathingScale = 1.0
            glowOpacity = 0.5
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        HStack(spacing: 40) {
            VStack {
                ShieldOrbView(isActive: true, size: 60)
                Text("Active").font(.caption)
            }
            VStack {
                ShieldOrbView(isActive: false, size: 60)
                Text("Inactive").font(.caption)
            }
        }

        HStack(spacing: 40) {
            ShieldOrbView(isActive: true, size: 24)
            ShieldOrbView(isActive: true, size: 48)
            ShieldOrbView(isActive: true, size: 80)
        }
    }
    .padding(40)
    .background(Color.pomBackground)
}
