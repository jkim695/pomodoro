import SwiftUI

/// Cosmic-themed card background with subtle gradient and optional glow effects
/// Used for the Limits feature to match the gamified aesthetic
struct CosmicCardModifier: ViewModifier {
    let isActive: Bool
    var cornerRadius: CGFloat = 16
    var showBorder: Bool = true
    var accentColor: Color = .pomShieldActive  // Customizable accent color

    @State private var breathingScale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base card background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.pomCardBackground)

                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.03),
                                    Color.clear,
                                    Color.black.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Active glow border
                    if isActive && showBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.4),
                                        accentColor.opacity(0.2),
                                        accentColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
            )
            .shadow(
                color: isActive ? accentColor.opacity(0.15) : Color.black.opacity(0.08),
                radius: isActive ? 12 : 8,
                x: 0,
                y: 4
            )
            .scaleEffect(breathingScale)
            .onAppear {
                if isActive {
                    startBreathing()
                }
            }
            .onChange(of: isActive) { newValue in
                if newValue {
                    startBreathing()
                } else {
                    stopBreathing()
                }
            }
    }

    private func startBreathing() {
        withAnimation(.cardActivePulse) {
            breathingScale = 1.005
        }
    }

    private func stopBreathing() {
        withAnimation(.easeOut(duration: 0.3)) {
            breathingScale = 1.0
        }
    }
}

/// Convenience view for wrapping content in a cosmic card
struct CosmicCard<Content: View>: View {
    let isActive: Bool
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 16
    var showBorder: Bool = true
    var accentColor: Color = .pomShieldActive
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .modifier(CosmicCardModifier(
                isActive: isActive,
                cornerRadius: cornerRadius,
                showBorder: showBorder,
                accentColor: accentColor
            ))
    }
}

extension View {
    func cosmicCard(isActive: Bool = false, cornerRadius: CGFloat = 16, showBorder: Bool = true, accentColor: Color = .pomShieldActive) -> some View {
        modifier(CosmicCardModifier(isActive: isActive, cornerRadius: cornerRadius, showBorder: showBorder, accentColor: accentColor))
    }
}

#Preview {
    VStack(spacing: 24) {
        CosmicCard(isActive: true) {
            HStack {
                ShieldOrbView(isActive: true, size: 40)
                VStack(alignment: .leading) {
                    Text("Active Schedule")
                        .font(.pomBody)
                        .foregroundColor(.pomTextPrimary)
                    Text("9:00 AM - 5:00 PM")
                        .font(.pomCaption)
                        .foregroundColor(.pomTextSecondary)
                }
                Spacer()
            }
        }

        CosmicCard(isActive: false) {
            HStack {
                ShieldOrbView(isActive: false, size: 40)
                VStack(alignment: .leading) {
                    Text("Inactive Schedule")
                        .font(.pomBody)
                        .foregroundColor(.pomTextPrimary)
                    Text("Weekends only")
                        .font(.pomCaption)
                        .foregroundColor(.pomTextSecondary)
                }
                Spacer()
            }
        }

        Text("Using modifier directly")
            .font(.pomBody)
            .foregroundColor(.pomTextPrimary)
            .padding()
            .cosmicCard(isActive: true)
    }
    .padding(24)
    .background(Color.pomBackground)
}
