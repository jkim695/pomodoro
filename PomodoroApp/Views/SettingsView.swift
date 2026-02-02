import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: PomodoroSession
    @EnvironmentObject var rewardsManager: RewardsManager
    @Environment(\.dismiss) private var dismiss
    @State private var showAppSelection = false

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

                        // About
                        settingsSection(title: "About", icon: "info.circle.fill") {
                            aboutSection
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
}
