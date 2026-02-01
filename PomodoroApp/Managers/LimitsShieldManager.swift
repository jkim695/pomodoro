import Foundation
import ManagedSettings
import FamilyControls

/// Manages app shielding using ManagedSettings for App Limits feature
/// Uses a separate named store to avoid conflicts with Pomodoro shields
final class LimitsShieldManager {
    static let shared = LimitsShieldManager()

    private let store = ManagedSettingsStore(named: .limits)

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

    /// Removes all shields applied by the limits feature
    func removeAllShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
    }

    /// Clears all managed settings for limits
    func clearAllSettings() {
        store.clearAllSettings()
    }
}
