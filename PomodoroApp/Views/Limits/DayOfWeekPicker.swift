import SwiftUI

/// Multi-select day of week picker component
struct DayOfWeekPicker: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Weekday.allCases) { day in
                dayButton(for: day)
            }
        }
    }

    private func dayButton(for day: Weekday) -> some View {
        let isSelected = selectedDays.contains(day)

        return Button {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            if isSelected {
                // Don't allow deselecting if it's the last day
                if selectedDays.count > 1 {
                    selectedDays.remove(day)
                }
            } else {
                selectedDays.insert(day)
            }
        } label: {
            Text(day.shortName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .pomTextSecondary)
                .frame(width: 38, height: 38)
                .background(
                    ZStack {
                        // Glow layer (only when selected)
                        if isSelected {
                            Circle()
                                .fill(Color.pomShieldActive.opacity(0.3))
                                .frame(width: 46, height: 46)
                                .blur(radius: 4)
                        }
                        // Main circle
                        Circle()
                            .fill(isSelected ? Color.pomShieldActive : Color.pomCardBackgroundAlt)
                            .shadow(
                                color: isSelected ? Color.pomShieldActive.opacity(0.5) : .clear,
                                radius: 6
                            )
                    }
                )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedDays)
    }
}

/// Quick preset buttons for day selection
struct DayPresetButtons: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        HStack(spacing: 12) {
            presetButton(title: "Every day", days: Weekday.allDays)
            presetButton(title: "Weekdays", days: Weekday.weekdays)
            presetButton(title: "Weekends", days: Weekday.weekend)
        }
    }

    private func presetButton(title: String, days: Set<Weekday>) -> some View {
        let isSelected = selectedDays == days

        return Button {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            selectedDays = days
        } label: {
            Text(title)
                .font(.pomCaption)
                .foregroundColor(isSelected ? .white : .pomTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(Color.pomShieldActive.opacity(0.3))
                                .blur(radius: 4)
                                .padding(-2)
                        }
                        Capsule()
                            .fill(isSelected ? Color.pomShieldActive : Color.pomCardBackgroundAlt)
                            .shadow(
                                color: isSelected ? Color.pomShieldActive.opacity(0.4) : .clear,
                                radius: 6
                            )
                    }
                )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedDays)
    }
}

#Preview {
    VStack(spacing: 24) {
        DayOfWeekPicker(selectedDays: .constant(Weekday.weekdays))
        DayPresetButtons(selectedDays: .constant(Weekday.allDays))
    }
    .padding()
}
