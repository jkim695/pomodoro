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
                .foregroundColor(style == .primary ? .white : .pomPeach)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    Group {
                        if style == .primary {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.pomPeach)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.pomPeach, lineWidth: 2)
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
            color: style == .primary ? Color.pomPeach.opacity(0.3) : .clear,
            radius: 8,
            x: 0,
            y: 4
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
            .foregroundColor(style == .primary ? .white : .pomPeach)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                Group {
                    if style == .primary {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.pomPeach)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.pomPeach, lineWidth: 2)
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
            color: style == .primary ? Color.pomPeach.opacity(0.3) : .clear,
            radius: 8,
            x: 0,
            y: 4
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
