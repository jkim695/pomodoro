import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: PomodoroSession
    @Environment(\.dismiss) private var dismiss
    @State private var showAppSelection = false

    private let focusDurations = [15, 25, 30, 45, 60, 90]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pomBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Focus Duration
                        settingsSection(title: "Set Duration", icon: "clock.fill") {
                            durationPicker(
                                values: focusDurations,
                                selected: $session.focusDuration,
                                suffix: "min"
                            )
                        }

                        // Blocked Apps
                        settingsSection(title: "Block Apps", icon: "shield.fill") {
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
                    .foregroundColor(.pomPrimary)
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
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.pomPrimary)

                Text(title)
                    .font(.pomHeading2)
                    .foregroundColor(.pomTextPrimary)
            }

            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pomCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
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
                    HStack(spacing: 4) {
                        Text("\(value)")
                            .font(.pomBody)
                            .fontWeight(.semibold)
                        Text(suffix)
                            .font(.pomCaption)
                    }
                    .foregroundColor(selected.wrappedValue == value ? .white : .pomTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selected.wrappedValue == value ? Color.pomPrimary : Color.pomCardBackgroundAlt)
                    )
                    .overlay(
                        Group {
                            if selected.wrappedValue == value {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pomPrimaryDark, lineWidth: 1)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pomBorder, lineWidth: 1)
                            }
                        }
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
                        .fontWeight(.medium)
                        .foregroundColor(.pomTextPrimary)

                    Text("Apps blocked during focus sessions")
                        .font(.pomCaption)
                        .foregroundColor(.pomTextSecondary)
                }

                Spacer()
            }

            RoundedButton("Manage Apps", style: .secondary) {
                showAppSelection = true
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PomodoroSession())
}
