import Foundation
import ManagedSettings
import FamilyControls

/// Named store identifiers for different shield contexts
extension ManagedSettingsStore.Name {
    static let pomodoro = Self("pomodoro")
    static let limits = Self("limits")
}

/// Manages app shielding using ManagedSettings for Pomodoro sessions
final class ShieldManager {
    static let shared = ShieldManager()

    private let store = ManagedSettingsStore(named: .pomodoro)

    private init() {}

    /// Applies shields to the selected apps and categories
    /// - Parameter selection: The FamilyActivitySelection containing apps/categories to shield
    func shieldApps(selection: FamilyActivitySelection) {
        // Shield selected applications
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens

        // Shield selected categories
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)

        // Shield web domains in selected categories
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
    }

    /// Removes all shields and clears managed settings
    func removeAllShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
    }

    /// Clears all managed settings (useful for cleanup)
    func clearAllSettings() {
        store.clearAllSettings()
    }
}
