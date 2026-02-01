import SwiftUI
import FamilyControls

struct ContentView: View {
    @EnvironmentObject var authorizationManager: AuthorizationManager
    @EnvironmentObject var session: PomodoroSession
    @EnvironmentObject var limitsSession: LimitsSession

    var body: some View {
        Group {
            switch authorizationManager.status {
            case .notDetermined:
                AuthorizationRequestView()
            case .approved:
                MainTabView()
            case .denied:
                AuthorizationDeniedView()
            }
        }
        .task {
            authorizationManager.checkStatus()
        }
        .alert("Error", isPresented: .init(
            get: { session.error != nil },
            set: { if !$0 { session.error = nil } }
        )) {
            Button("OK") {
                session.error = nil
            }
        } message: {
            if let error = session.error {
                Text(error)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthorizationManager())
        .environmentObject(PomodoroSession())
        .environmentObject(LimitsSession())
        .environmentObject(RewardsManager.shared)
}
