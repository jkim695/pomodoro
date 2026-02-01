import Foundation
import UserNotifications

/// Manages local notifications for focus completion
final class NotificationManager {
    static let shared = NotificationManager()

    private let focusCompleteIdentifier = "pomodoro.focus.complete"

    private init() {}

    /// Requests notification permission from the user
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }

    /// Schedules a notification for when the focus session completes
    /// - Parameter seconds: Time in seconds until notification
    func scheduleFocusComplete(in seconds: Int) {
        scheduleNotification(
            identifier: focusCompleteIdentifier,
            title: "Focus Complete!",
            body: "Great work! Session complete.",
            seconds: seconds
        )
    }

    /// Cancels all pending notifications
    func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    /// Cancels only the focus complete notification
    func cancelFocusNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [focusCompleteIdentifier])
    }

    // MARK: - Private Methods

    private func scheduleNotification(identifier: String, title: String, body: String, seconds: Int) {
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
}
