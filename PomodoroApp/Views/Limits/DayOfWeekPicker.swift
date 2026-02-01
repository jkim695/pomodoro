import SwiftUI

/// Multi-select day of week picker component
struct DayOfWeekPicker: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Weekday.allCases) { day in
                dayButton(for: day)
            }
        }
    }

    private func dayButton(for day: Weekday) -> some View {
        Button {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            if selectedDays.contains(day) {
                // Don't allow deselecting if it's the last day
                if selectedDays.count > 1 {
                    selectedDays.remove(day)
                }
            } else {
                selectedDays.insert(day)
            }
        } label: {
            Text(day.shortName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(selectedDays.contains(day) ? .white : .pomTextPrimary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(selectedDays.contains(day) ? Color.pomPrimary : Color.pomCardBackgroundAlt)
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
        Button {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            selectedDays = days
        } label: {
            Text(title)
                .font(.pomCaption)
                .foregroundColor(selectedDays == days ? .white : .pomTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selectedDays == days ? Color.pomPrimary : Color.pomCardBackgroundAlt)
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
