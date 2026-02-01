import SwiftUI
import FamilyControls

/// Editor view for creating or editing a time schedule
struct TimeScheduleEditorView: View {
    @EnvironmentObject var limitsSession: LimitsSession
    @Environment(\.dismiss) private var dismiss

    let schedule: TimeSchedule?

    @State private var name: String = "New Schedule"
    @State private var selection = FamilyActivitySelection()
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var activeDays: Set<Weekday> = Weekday.allDays
    @State private var showAppSelection = false

    private var isEditing: Bool { schedule != nil }

    init(schedule: TimeSchedule?) {
        self.schedule = schedule

        if let schedule = schedule {
            _name = State(initialValue: schedule.name)
            _selection = State(initialValue: schedule.selection)
            _activeDays = State(initialValue: schedule.activeDays)

            // Convert hour/minute to Date for picker
            let calendar = Calendar.current
            var startComponents = DateComponents()
            startComponents.hour = schedule.startHour
            startComponents.minute = schedule.startMinute
            _startTime = State(initialValue: calendar.date(from: startComponents) ?? Date())

            var endComponents = DateComponents()
            endComponents.hour = schedule.endHour
            endComponents.minute = schedule.endMinute
            _endTime = State(initialValue: calendar.date(from: endComponents) ?? Date())
        } else {
            // Default: 9pm to 7am
            let calendar = Calendar.current
            var startComponents = DateComponents()
            startComponents.hour = 21
            startComponents.minute = 0
            _startTime = State(initialValue: calendar.date(from: startComponents) ?? Date())

            var endComponents = DateComponents()
            endComponents.hour = 7
            endComponents.minute = 0
            _endTime = State(initialValue: calendar.date(from: endComponents) ?? Date())
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pomBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Name
                        editorSection(title: "Name", icon: "pencil") {
                            TextField("Schedule name", text: $name)
                                .font(.pomBody)
                                .foregroundColor(.pomTextPrimary)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.pomCardBackgroundAlt)
                                )
                        }

                        // Time Range
                        editorSection(title: "Time Range", icon: "clock") {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("From")
                                        .font(.pomBody)
                                        .foregroundColor(.pomTextSecondary)

                                    Spacer()

                                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .tint(.pomShieldActive)
                                }

                                HStack {
                                    Text("To")
                                        .font(.pomBody)
                                        .foregroundColor(.pomTextSecondary)

                                    Spacer()

                                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .tint(.pomShieldActive)
                                }

                                if isOvernight {
                                    HStack {
                                        Image(systemName: "moon.fill")
                                            .foregroundColor(.pomShieldActive)
                                        Text("This schedule runs overnight")
                                            .font(.pomCaption)
                                            .foregroundColor(.pomTextSecondary)
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.pomShieldActive.opacity(0.1))
                                    )
                                }
                            }
                        }

                        // Days
                        editorSection(title: "Active Days", icon: "calendar") {
                            VStack(spacing: 16) {
                                DayOfWeekPicker(selectedDays: $activeDays)
                                DayPresetButtons(selectedDays: $activeDays)
                            }
                        }

                        // Apps
                        editorSection(title: "Apps to Block", icon: "shield.fill") {
                            VStack(spacing: 12) {
                                let appCount = selection.applicationTokens.count + selection.categoryTokens.count

                                HStack {
                                    Text("\(appCount) item\(appCount == 1 ? "" : "s") selected")
                                        .font(.pomBody)
                                        .foregroundColor(.pomTextPrimary)
                                    Spacer()
                                }

                                Button {
                                    showAppSelection = true
                                } label: {
                                    HStack {
                                        Text("Select Apps")
                                            .font(.pomButton)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundColor(.pomShieldActive)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.pomShieldActive.opacity(0.1))
                                    )
                                }
                            }
                        }

                        // Save Button
                        RoundedButton(isEditing ? "Save Changes" : "Create Schedule", style: .primary) {
                            saveSchedule()
                        }
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(isEditing ? "Edit Schedule" : "New Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.pomTextSecondary)
                }
            }
        }
        .sheet(isPresented: $showAppSelection) {
            ScheduleAppSelectionView(selection: $selection)
        }
    }

    // MARK: - Editor Section
    private func editorSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.pomShieldActive)

                Text(title)
                    .font(.pomBody)
                    .fontWeight(.medium)
                    .foregroundColor(.pomTextPrimary)
            }

            content()
        }
        .padding(16)
        .cosmicCard(isActive: false, cornerRadius: 16, showBorder: false)
    }

    // MARK: - Computed Properties
    private var isOvernight: Bool {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startTime)
        let endHour = calendar.component(.hour, from: endTime)
        let startMinute = calendar.component(.minute, from: startTime)
        let endMinute = calendar.component(.minute, from: endTime)

        if startHour > endHour {
            return true
        } else if startHour == endHour {
            return startMinute > endMinute
        }
        return false
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (!selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty) &&
        !activeDays.isEmpty
    }

    // MARK: - Actions
    private func saveSchedule() {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startTime)
        let startMinute = calendar.component(.minute, from: startTime)
        let endHour = calendar.component(.hour, from: endTime)
        let endMinute = calendar.component(.minute, from: endTime)

        if let existingSchedule = schedule {
            // Update existing
            var updated = existingSchedule
            updated.name = name.trimmingCharacters(in: .whitespaces)
            updated.selection = selection
            updated.startHour = startHour
            updated.startMinute = startMinute
            updated.endHour = endHour
            updated.endMinute = endMinute
            updated.activeDays = activeDays
            limitsSession.updateSchedule(updated)
        } else {
            // Create new
            let newSchedule = TimeSchedule(
                name: name.trimmingCharacters(in: .whitespaces),
                selection: selection,
                startHour: startHour,
                startMinute: startMinute,
                endHour: endHour,
                endMinute: endMinute,
                activeDays: activeDays
            )
            limitsSession.addSchedule(newSchedule)
        }

        dismiss()
    }
}

/// App selection view for schedules
struct ScheduleAppSelectionView: View {
    @Binding var selection: FamilyActivitySelection
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pomBackground
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ShieldOrbView(isActive: true, size: 48)

                        Text("Apps to Block")
                            .font(.pomHeading2)
                            .foregroundColor(.pomTextPrimary)

                        Text("Select apps and categories to block during this schedule.")
                            .font(.pomBody)
                            .foregroundColor(.pomTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)

                    FamilyActivityPicker(selection: $selection)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.pomCardBackground)
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.pomButton)
                    .foregroundColor(.pomShieldActive)
                }
            }
        }
    }
}

#Preview {
    TimeScheduleEditorView(schedule: nil)
        .environmentObject(LimitsSession())
}
