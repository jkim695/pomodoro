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

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name)
                    .font(.pomBody)
                    .fontWeight(.medium)
                    .foregroundColor(.pomBrown)

                Text(schedule.formattedTimeRange)
                    .font(.pomCaption)
                    .foregroundColor(.pomLightBrown)

                HStack(spacing: 4) {
                    Text(schedule.activeDaysSummary)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.pomLightBrown)

                    Text("•")
                        .foregroundColor(.pomLightBrown)

                    Text("\(schedule.selectionCount) app\(schedule.selectionCount == 1 ? "" : "s")")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.pomLightBrown)
                }
            }

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { onToggle($0) }
            ))
            .tint(.pomPeach)
            .labelsHidden()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pomCream)
        )
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
    .environmentObject(LimitsSession())
}
