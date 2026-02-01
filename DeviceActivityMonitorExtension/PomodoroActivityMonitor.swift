import DeviceActivity
import ManagedSettings
import FamilyControls

/// Monitors device activity and manages shields during focus sessions
class PomodoroActivityMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()

    /// Called when the focus session interval starts
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Load the saved selection and apply shields
        guard let selection = SharedDataManager.shared.loadSelection() else {
            return
        }

        applyShields(for: selection)
        SharedDataManager.shared.isSessionActive = true
    }

    /// Called when the focus session interval ends
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        removeAllShields()
        SharedDataManager.shared.isSessionActive = false
    }

    // MARK: - Private Methods

    private func applyShields(for selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens.isEmpty
            ? nil
            : selection.applicationTokens

        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)

        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
    }

    private func removeAllShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
    }
}
