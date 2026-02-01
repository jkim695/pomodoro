import Foundation
import FamilyControls

/// Manages Screen Time authorization status
@MainActor
final class AuthorizationManager: ObservableObject {
    @Published private(set) var status: AuthorizationStatus = .notDetermined

    private let authorizationCenter = AuthorizationCenter.shared

    init() {
        checkStatus()
    }

    /// Checks the current authorization status
    func checkStatus() {
        status = authorizationCenter.authorizationStatus
    }

    /// Requests Screen Time authorization for individual use
    func requestAuthorization() async {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            checkStatus()
        } catch {
            print("Authorization request failed: \(error)")
            checkStatus()
        }
    }

    /// Whether the app is authorized to use Screen Time features
    var isAuthorized: Bool {
        status == .approved
    }
}
