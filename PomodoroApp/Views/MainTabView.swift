import SwiftUI

/// Main tab navigation container with Timer and Limits tabs
struct MainTabView: View {
    @EnvironmentObject var session: PomodoroSession
    @EnvironmentObject var limitsSession: LimitsSession

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
        }
        .tint(Color.pomPrimary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(PomodoroSession())
        .environmentObject(LimitsSession())
}
