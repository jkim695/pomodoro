import SwiftUI

struct AvatarMessageView: View {
    let message: String
    let style: MessageStyle
    @State private var isVisible = false

    enum MessageStyle {
        case encouragement  // "Stay focused!"
        case celebration    // "Great job!"

        var backgroundColor: Color {
            switch self {
            case .encouragement:
                return Color.pomPeach
            case .celebration:
                return Color.pomSage
            }
        }

        var textColor: Color {
            return Color.pomBrown
        }
    }

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(style.textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(style.backgroundColor)
                    .shadow(color: Color.pomBrown.opacity(0.15), radius: 4, y: 2)
            )
            .scaleEffect(isVisible ? 1.0 : 0.5)
            .opacity(isVisible ? 1.0 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isVisible = true
                }
            }
    }
}

struct AvatarWithMessage: View {
    let avatarState: AvatarState
    let avatarSize: CGFloat
    var showGroundingShadow: Bool = true  // Can disable shadow when inside a circle
    @State private var showMessage = false
    @State private var messageText = ""
    @State private var messageStyle: AvatarMessageView.MessageStyle = .encouragement

    var body: some View {
        VStack(spacing: 4) {
            // Message bubble (above avatar)
            if showMessage {
                AvatarMessageView(message: messageText, style: messageStyle)
                    .transition(.scale.combined(with: .opacity))
            }

            // Avatar with optional grounding shadow
            ZStack {
                // Grounding shadow (ellipse under feet) - only when enabled
                if showGroundingShadow {
                    Ellipse()
                        .fill(Color.pomBrown.opacity(0.35))
                        .frame(width: avatarSize * 0.5, height: avatarSize * 0.12)
                        .blur(radius: 2)
                        .offset(y: avatarSize * 0.38)
                }

                // Avatar
                AvatarView(state: avatarState, size: avatarSize)
            }

            // Sparkles for celebration
            if avatarState == .celebrating {
                SparkleView(size: avatarSize)
                    .offset(y: -avatarSize * 0.3)
            }
        }
        .onChange(of: avatarState) { newState in
            handleStateChange(newState)
        }
        .onAppear {
            handleStateChange(avatarState)
        }
    }

    private func handleStateChange(_ state: AvatarState) {
        switch state {
        case .celebrating:
            messageText = "Great job!"
            messageStyle = .celebration
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showMessage = true
            }
            dismissMessageAfterDelay()

        case .disappointed:
            messageText = "Stay focused!"
            messageStyle = .encouragement
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showMessage = true
            }
            dismissMessageAfterDelay()

        default:
            withAnimation(.easeOut(duration: 0.2)) {
                showMessage = false
            }
        }
    }

    private func dismissMessageAfterDelay() {
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    showMessage = false
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        AvatarWithMessage(avatarState: .celebrating, avatarSize: 100)
        AvatarWithMessage(avatarState: .disappointed, avatarSize: 100)
    }
    .padding()
    .background(Color.pomCream)
}
