import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: PomodoroSession
    @Environment(\.dismiss) private var dismiss
    @State private var showAppSelection = false

    private let focusDurations = [15, 20, 25, 30, 45, 60]
    private let breakDurations = [5, 10, 15, 20]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pomCream
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Focus Duration
                        settingsSection(title: "Focus Duration", icon: "timer") {
                            durationPicker(
                                values: focusDurations,
                                selected: $session.focusDuration,
                                suffix: "min"
                            )
                        }

                        // Break Duration
                        settingsSection(title: "Break Duration", icon: "cup.and.saucer") {
                            durationPicker(
                                values: breakDurations,
                                selected: $session.breakDuration,
                                suffix: "min"
                            )
                        }

                        // Blocked Apps
                        settingsSection(title: "Blocked Apps", icon: "apps.iphone") {
                            blockedAppsSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.pomButton)
                    .foregroundColor(.pomPeach)
                }
            }
        }
        .sheet(isPresented: $showAppSelection) {
            AppSelectionView()
        }
    }

    // MARK: - Settings Section
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.pomPeach)

                Text(title)
                    .font(.pomHeading)
                    .foregroundColor(.pomBrown)
            }

            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.pomBrown.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Duration Picker
    private func durationPicker(
        values: [Int],
        selected: Binding<Int>,
        suffix: String
    ) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(values, id: \.self) { value in
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    selected.wrappedValue = value
                } label: {
                    Text("\(value) \(suffix)")
                        .font(.pomBody)
                        .foregroundColor(selected.wrappedValue == value ? .white : .pomBrown)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selected.wrappedValue == value ? Color.pomPeach : Color.pomCream)
                        )
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected.wrappedValue)
            }
        }
    }

    // MARK: - Blocked Apps Section
    private var blockedAppsSection: some View {
        VStack(spacing: 16) {
            let appCount = session.selection.applicationTokens.count + session.selection.categoryTokens.count

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(appCount) item\(appCount == 1 ? "" : "s") selected")
                        .font(.pomBody)
                        .foregroundColor(.pomBrown)

                    Text("Apps and categories to block during focus")
                        .font(.pomCaption)
                        .foregroundColor(.pomLightBrown)
                }

                Spacer()
            }

            RoundedButton("Manage Blocked Apps", style: .secondary) {
                showAppSelection = true
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PomodoroSession())
}
