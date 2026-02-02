import SwiftUI

/// Main tab navigation container with Timer, Limits, and Rewards tabs
struct MainTabView: View {
    @EnvironmentObject var session: PomodoroSession
    @EnvironmentObject var limitsSession: LimitsSession
    @EnvironmentObject var rewardsManager: RewardsManager

    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "clock.fill")
                }

            LimitsView()
                .tabItem {
                    Label("Limits", systemImage: "shield.fill")
                }

            RewardsTabView()
                .tabItem {
                    Label("Rewards", systemImage: "sparkles")
                }
        }
        .tint(rewardsManager.equippedStyle.primaryColor)
        .toolbar(session.state == .idle ? .visible : .hidden, for: .tabBar)
    }
}

#Preview {
    MainTabView()
        .environmentObject(PomodoroSession())
        .environmentObject(LimitsSession())
        .environmentObject(RewardsManager.shared)
}
