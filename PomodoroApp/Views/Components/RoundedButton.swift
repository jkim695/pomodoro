import SwiftUI

enum ButtonStyle {
    case primary
    case secondary
    case destructive
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
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.pomButton)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.horizontal, 32)
                .background(background)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .pomPrimary
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? Color.pomPrimaryDark : Color.pomPrimary)
                .shadow(color: Color.pomPrimary.opacity(0.3), radius: 8, x: 0, y: 4)

        case .secondary:
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pomPrimaryLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pomPrimary, lineWidth: 2)
                )

        case .destructive:
            RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? Color.pomDestructive.opacity(0.8) : Color.pomDestructive)
                .shadow(color: Color.pomDestructive.opacity(0.3), radius: 8, x: 0, y: 4)
        }
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
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.pomButton)
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 32)
            .background(background)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .pomPrimary
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? Color.pomPrimaryDark : Color.pomPrimary)
                .shadow(color: Color.pomPrimary.opacity(0.3), radius: 8, x: 0, y: 4)

        case .secondary:
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pomPrimaryLight)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pomPrimary, lineWidth: 2)
                )

        case .destructive:
            RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? Color.pomDestructive.opacity(0.8) : Color.pomDestructive)
                .shadow(color: Color.pomDestructive.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RoundedButton("Begin", style: .primary) {}
        RoundedButton("Skip Break", style: .secondary) {}
        RoundedButton("Delete", style: .destructive) {}
        IconRoundedButton("Select Apps", icon: "apps.iphone", style: .secondary) {}
    }
    .padding()
    .background(Color.pomBackground)
}
