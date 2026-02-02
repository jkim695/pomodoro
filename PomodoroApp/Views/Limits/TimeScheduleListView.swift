import SwiftUI

/// List view showing all time-based schedules
struct TimeScheduleListView: View {
    @EnvironmentObject var limitsSession: LimitsSession
    @State private var editingSchedule: TimeSchedule?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(limitsSession.schedules) { schedule in
                ScheduleRow(schedule: schedule) {
                    editingSchedule = schedule
                } onToggle: { enabled in
                    limitsSession.toggleSchedule(id: schedule.id, enabled: enabled)
                } onDelete: {
                    limitsSession.deleteSchedule(id: schedule.id)
                }
            }
        }
        .sheet(item: $editingSchedule) { schedule in
            TimeScheduleEditorView(schedule: schedule)
        }
    }
}

/// Row component for a single schedule
struct ScheduleRow: View {
    let schedule: TimeSchedule
    let onEdit: () -> Void
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void
    @EnvironmentObject var rewardsManager: RewardsManager

    @State private var showDeleteConfirmation = false

    private var accentColor: Color {
        rewardsManager.equippedStyle.primaryColor
    }

    var body: some View {
        HStack(spacing: 12) {
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(schedule.name)
                    .font(.pomBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.pomTextPrimary)

                // Time range and app count on same line
                HStack(spacing: 0) {
                    Text(schedule.formattedTimeRange)
                        .font(.pomCaption)
                        .foregroundColor(.pomTextSecondary)

                    Text(" · \(schedule.selectionCount) app\(schedule.selectionCount == 1 ? "" : "s")")
                        .font(.pomCaption)
                        .foregroundColor(.pomTextTertiary)
                }

                // Glowing day pills
                HStack(spacing: 6) {
                    ForEach(Weekday.allCases) { day in
                        let isActive = schedule.activeDays.contains(day)
                        Text(day.shortName)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(isActive ? .white : .pomTextTertiary)
                            .frame(width: 22, height: 22)
                            .background(
                                ZStack {
                                    if isActive && schedule.isEnabled {
                                        Circle()
                                            .fill(accentColor.opacity(0.3))
                                            .frame(width: 26, height: 26)
                                            .blur(radius: 3)
                                    }
                                    Circle()
                                        .fill(isActive ? accentColor : Color.pomCardBackgroundAlt)
                                }
                            )
                    }
                }
                .padding(.top, 2)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { onToggle($0) }
            ))
            .tint(accentColor)
            .labelsHidden()
        }
        .padding(16)
        .cosmicCard(isActive: schedule.isEnabled, cornerRadius: 12)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete Schedule", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(schedule.name)\"?")
        }
    }
}

#Preview {
    VStack {
        TimeScheduleListView()
    }
    .padding()
    .background(Color.pomBackground)
    .environmentObject(LimitsSession())
}
