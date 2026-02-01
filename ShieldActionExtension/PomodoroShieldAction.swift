import ManagedSettingsUI
import ManagedSettings

/// Handles user interactions with the shield overlay
class PomodoroShieldAction: ShieldActionDelegate {
    private let pomodoroStore = ManagedSettingsStore(named: .pomodoro)
    private let limitsStore = ManagedSettingsStore(named: .limits)

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
        let context = SharedDataManager.shared.shieldContext

        switch action {
        case .primaryButtonPressed:
            // Primary button always closes the shield
            completionHandler(.close)

        case .secondaryButtonPressed:
            // Secondary button behavior depends on context
            switch context {
            case .pomodoro:
                // "End Session" - remove shields and mark session as ended early
                removeShields(from: pomodoroStore)
                SharedDataManager.shared.sessionEndedEarly = true
                SharedDataManager.shared.isSessionActive = false
                SharedDataManager.shared.clearShieldContext()
                completionHandler(.close)

            case .timeSchedule, .usageLimit, nil:
                // Time schedules and usage limits don't have a secondary button
                // But if somehow pressed, just close
                completionHandler(.close)
            }

        @unknown default:
            completionHandler(.close)
        }
    }

    private func removeShields(from store: ManagedSettingsStore) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
    }
}

// Extension to access ManagedSettingsStore names from extensions
extension ManagedSettingsStore.Name {
    static let pomodoro = Self("pomodoro")
    static let limits = Self("limits")
}
