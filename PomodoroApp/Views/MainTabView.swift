import SwiftUI

/// Main tab navigation container with Timer and Limits tabs
struct MainTabView: View {
    @EnvironmentObject var session: PomodoroSession
    @EnvironmentObject var limitsSession: LimitsSession

    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            LimitsView()
                .tabItem {
                    Label("Limits", systemImage: "hourglass")
                }
        }
        .tint(Color.pomPeach)
    }
}

#Preview {
    MainTabView()
        .environmentObject(PomodoroSession())
        .environmentObject(LimitsSession())
}
