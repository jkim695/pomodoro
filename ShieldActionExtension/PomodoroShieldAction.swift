import ManagedSettingsUI
import ManagedSettings

/// Handles user interactions with the shield overlay
class PomodoroShieldAction: ShieldActionDelegate {
    private let store = ManagedSettingsStore()

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    // MARK: - Private Methods

    private func handleAction(
        _ action: ShieldAction,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            // "Back to Work" - just close the shield and return to home
            completionHandler(.close)

        case .secondaryButtonPressed:
            // "End Session" - remove shields and mark session as ended early
            removeAllShields()
            SharedDataManager.shared.sessionEndedEarly = true
            SharedDataManager.shared.isSessionActive = false
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    private func removeAllShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
    }
}
