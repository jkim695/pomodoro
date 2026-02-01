import SwiftUI

struct AuthorizationRequestView: View {
    @EnvironmentObject var authorizationManager: AuthorizationManager
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.pomCream
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Illustration
                illustrationSection

                // Content
                contentSection

                Spacer()

                // Action button
                actionButton

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Illustration
    private var illustrationSection: some View {
        ZStack {
            Circle()
                .fill(Color.pomPeach.opacity(0.2))
                .frame(width: 160, height: 160)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            Circle()
                .fill(Color.pomPeach.opacity(0.3))
                .frame(width: 120, height: 120)

            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.pomSage)
        }
        .onAppear {
            isAnimating = true
        }
    }

    // MARK: - Content
    private var contentSection: some View {
        VStack(spacing: 16) {
            Text("Focus Better")
                .font(.pomHeading)
                .foregroundColor(.pomBrown)

            Text("To help you stay focused, we need access to Screen Time. This lets us block distracting apps during your focus sessions.")
                .font(.pomBody)
                .foregroundColor(.pomLightBrown)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Benefits
            VStack(alignment: .leading, spacing: 12) {
                benefitRow(icon: "checkmark.circle.fill", text: "Block distracting apps")
                benefitRow(icon: "checkmark.circle.fill", text: "Stay on track")
                benefitRow(icon: "checkmark.circle.fill", text: "Build focus habits")
            }
            .padding(.top, 16)
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.pomSage)

            Text(text)
                .font(.pomBody)
                .foregroundColor(.pomBrown)

            Spacer()
        }
    }

    // MARK: - Action Button
    private var actionButton: some View {
        RoundedButton("Get Started", style: .primary) {
            Task {
                await authorizationManager.requestAuthorization()
            }
        }
    }
}

// MARK: - Denied State View
struct AuthorizationDeniedView: View {
    var body: some View {
        ZStack {
            Color.pomCream
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pomPeach)

                VStack(spacing: 16) {
                    Text("Screen Time Access Needed")
                        .font(.pomHeading)
                        .foregroundColor(.pomBrown)

                    Text("Please enable Screen Time access in Settings to use this app's focus features.")
                        .font(.pomBody)
                        .foregroundColor(.pomLightBrown)
                        .multilineTextAlignment(.center)
                }

                RoundedButton("Open Settings", style: .primary) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    AuthorizationRequestView()
        .environmentObject(AuthorizationManager())
}
