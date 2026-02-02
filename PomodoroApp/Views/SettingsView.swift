import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: PomodoroSession
    @EnvironmentObject var rewardsManager: RewardsManager
    @EnvironmentObject var limitsSession: LimitsSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showAppSelection = false
    @State private var showDeleteConfirmation = false
    @State private var showFinalDeleteConfirmation = false
    @State private var deleteConfirmationText = ""

    // AppStorage keys that need to be reset
    @AppStorage("completedSessions") private var completedSessions: Int = 0
    @AppStorage("focusedMinutesToday") private var focusedMinutesToday: Int = 0
    @AppStorage("lastFocusDate") private var lastFocusDate: String = ""
    @AppStorage("focusDuration") private var focusDuration: Int = 25

    /// Adaptive horizontal padding
    private var horizontalPadding: CGFloat {
        sizeClass == .regular ? 40 : 24
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pomBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Blocked Apps
                        settingsSection(title: "Block Apps", icon: "shield.fill") {
                            blockedAppsSection
                        }

                        // Data Management
                        settingsSection(title: "Data", icon: "cylinder.split.1x2.fill") {
                            dataManagementSection
                        }

                        // About
                        settingsSection(title: "About", icon: "info.circle.fill") {
                            aboutSection
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, sizeClass == .regular ? 24 : 16)
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
                    .accessibilityLabel("Done")
                    .accessibilityHint("Close settings")
                }
            }
        }
        .sheet(isPresented: $showAppSelection) {
            AppSelectionView()
        }
        .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Continue", role: .destructive) {
                showFinalDeleteConfirmation = true
            }
        } message: {
            Text("This will permanently delete all your progress, Stardust balance, orb collection, schedules, and limits. This action cannot be undone.")
        }
        .alert("Confirm Deletion", isPresented: $showFinalDeleteConfirmation) {
            TextField("Type DELETE to confirm", text: $deleteConfirmationText)
            Button("Cancel", role: .cancel) {
                deleteConfirmationText = ""
            }
            Button("Delete Everything", role: .destructive) {
                if deleteConfirmationText.uppercased() == "DELETE" {
                    performDataDeletion()
                }
                deleteConfirmationText = ""
            }
        } message: {
            Text("Type DELETE to confirm you want to erase all data.")
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

    // MARK: - Data Management Section
    private var dataManagementSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reset App Data")
                        .font(.pomBody)
                        .fontWeight(.medium)
                        .foregroundColor(.pomTextPrimary)

                    Text("Delete all progress, Stardust, orbs, and limits")
                        .font(.pomCaption)
                        .foregroundColor(.pomTextSecondary)
                }

                Spacer()
            }

            RoundedButton("Delete All Data", style: .destructive) {
                showDeleteConfirmation = true
            }
        }
    }

    // MARK: - Data Deletion
    private func performDataDeletion() {
        // Reset rewards (balance, progress, collection, gacha)
        rewardsManager.deleteAllData()

        // Reset limits (schedules, limits, usage records)
        limitsSession.deleteAllData()

        // Reset @AppStorage values
        completedSessions = 0
        focusedMinutesToday = 0
        lastFocusDate = ""
        focusDuration = 25

        // Dismiss settings after deletion
        dismiss()
    }

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 12) {
            Link(destination: URL(string: "https://jkim695.github.io/pomodoro/privacy-policy")!) {
                HStack {
                    Text("Privacy Policy")
                        .font(.pomBody)
                        .foregroundColor(.pomTextPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14))
                        .foregroundColor(.pomTextSecondary)
                }
            }
            .accessibilityLabel("Privacy Policy")
            .accessibilityHint("Opens in web browser")

            Divider()
                .background(Color.pomBorder)

            HStack {
                Text("Version")
                    .font(.pomBody)
                    .foregroundColor(.pomTextPrimary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .font(.pomBody)
                    .foregroundColor(.pomTextSecondary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PomodoroSession())
        .environmentObject(RewardsManager.shared)
        .environmentObject(LimitsSession())
}
