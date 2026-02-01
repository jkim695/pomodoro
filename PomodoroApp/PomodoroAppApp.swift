import SwiftUI

@main
struct PomodoroAppApp: App {
    @StateObject private var authorizationManager = AuthorizationManager()
    @StateObject private var session = PomodoroSession()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authorizationManager)
                .environmentObject(session)
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
