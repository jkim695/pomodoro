import Foundation
import FamilyControls

/// Manages shared data between the main app and extensions using App Groups
final class SharedDataManager {
    static let shared = SharedDataManager()

    private let suiteName = "group.com.pomodoro.app"
    private let selectionKey = "familyActivitySelection"
    private let sessionActiveKey = "isSessionActive"
    private let sessionEndedEarlyKey = "sessionEndedEarly"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private init() {}

    // MARK: - Family Activity Selection

    /// Saves the user's app selection to shared storage
    /// - Parameter selection: The FamilyActivitySelection to persist
    func saveSelection(_ selection: FamilyActivitySelection) {
        guard let defaults = userDefaults else { return }

        do {
            let data = try PropertyListEncoder().encode(selection)
            defaults.set(data, forKey: selectionKey)
        } catch {
            print("Failed to save selection: \(error)")
        }
    }

    /// Loads the previously saved app selection
    /// - Returns: The saved FamilyActivitySelection, or nil if none exists
    func loadSelection() -> FamilyActivitySelection? {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: selectionKey) else {
            return nil
        }

        do {
            return try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            print("Failed to load selection: \(error)")
            return nil
        }
    }

    /// Clears the saved selection
    func clearSelection() {
        userDefaults?.removeObject(forKey: selectionKey)
    }

    // MARK: - Session State

    /// Whether a focus session is currently active
    var isSessionActive: Bool {
        get {
            userDefaults?.bool(forKey: sessionActiveKey) ?? false
        }
        set {
            userDefaults?.set(newValue, forKey: sessionActiveKey)
        }
    }

    /// Whether the user ended the session early via shield action
    var sessionEndedEarly: Bool {
        get {
            userDefaults?.bool(forKey: sessionEndedEarlyKey) ?? false
        }
        set {
            userDefaults?.set(newValue, forKey: sessionEndedEarlyKey)
        }
    }

    /// Resets all session-related state
    func resetSessionState() {
        isSessionActive = false
        sessionEndedEarly = false
    }
}
