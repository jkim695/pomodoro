import SwiftUI

enum ButtonStyle {
    case primary
    case secondary
}

struct RoundedButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void

    @State private var isPressed = false

    init(_ title: String, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    var body: some View {
        Button {
            // Light haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.pomButton)
                .foregroundColor(style == .primary ? .white : .pomBrown)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 32)
                .background(
                    Group {
                        if style == .primary {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.pomPeach)
                        } else {
                            // Filled background with chunky border for kawaii aesthetic
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.pomPeach.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.pomPeach, lineWidth: 3.5)
                                )
                        }
                    }
                )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .shadow(
            color: Color.pomPeach.opacity(style == .primary ? 0.3 : 0.2),
            radius: style == .primary ? 8 : 6,
            x: 0,
            y: style == .primary ? 4 : 3
        )
    }
}

// MARK: - Icon Button Variant
struct IconRoundedButton: View {
    let title: String
    let icon: String
    let style: ButtonStyle
    let action: () -> Void

    @State private var isPressed = false

    init(_ title: String, icon: String, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.pomButton)
            .foregroundColor(style == .primary ? .white : .pomBrown)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 32)
            .background(
                Group {
                    if style == .primary {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.pomPeach)
                    } else {
                        // Filled background with chunky border for kawaii aesthetic
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.pomPeach.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.pomPeach, lineWidth: 3.5)
                            )
                    }
                }
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .shadow(
            color: Color.pomPeach.opacity(style == .primary ? 0.3 : 0.2),
            radius: style == .primary ? 8 : 6,
            x: 0,
            y: style == .primary ? 4 : 3
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        RoundedButton("Start Focus", style: .primary) {}
        RoundedButton("Skip Break", style: .secondary) {}
        IconRoundedButton("Select Apps", icon: "apps.iphone", style: .secondary) {}
    }
    .padding()
    .background(Color.pomCream)
}
