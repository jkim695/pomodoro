import SwiftUI

@main
struct PomodoroAppApp: App {
    @StateObject private var authorizationManager = AuthorizationManager()
    @StateObject private var session = PomodoroSession()
    @StateObject private var limitsSession = LimitsSession()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authorizationManager)
                .environmentObject(session)
                .environmentObject(limitsSession)
                .onChange(of: scenePhase) { newPhase in
                    handleScenePhaseChange(to: newPhase)
                }
        }
    }

    private func handleScenePhaseChange(to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // App became active - check for background changes
            Task { @MainActor in
                session.handleAppBecameActive()
                limitsSession.handleAppBecameActive()
            }
        case .background:
            // App going to background - timer state is already persisted by TimerManager
            break
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}
