import ManagedSettingsUI
import ManagedSettings
import UIKit

/// Provides custom shield appearance for blocked apps
class PomodoroShieldConfiguration: ShieldConfigurationDataSource {

    // MARK: - Color Palette (Warm Earth Tones)

    private var peachColor: UIColor {
        UIColor(red: 255/255, green: 203/255, blue: 164/255, alpha: 1.0) // #FFCBA4
    }

    private var creamColor: UIColor {
        UIColor(red: 255/255, green: 248/255, blue: 231/255, alpha: 1.0) // #FFF8E7
    }

    private var sageColor: UIColor {
        UIColor(red: 178/255, green: 201/255, blue: 173/255, alpha: 1.0) // #B2C9AD
    }

    private var darkTextColor: UIColor {
        UIColor(red: 60/255, green: 60/255, blue: 60/255, alpha: 1.0)
    }

    private var redColor: UIColor {
        UIColor(red: 200/255, green: 80/255, blue: 80/255, alpha: 1.0)
    }

    // MARK: - Shield Configuration

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        createShieldConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        createShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        createShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        createShieldConfiguration()
    }

    // MARK: - Private Methods

    private func createShieldConfiguration() -> ShieldConfiguration {
        let context = SharedDataManager.shared.shieldContext

        switch context {
        case .pomodoro:
            return createPomodoroShield()

        case .timeSchedule:
            return createTimeScheduleShield()

        case .usageLimit:
            return createUsageLimitShield()

        case nil:
            // Default to Pomodoro style if no context
            return createPomodoroShield()
        }
    }

    private func createPomodoroShield() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .light,
            backgroundColor: creamColor,
            icon: nil,
            title: ShieldConfiguration.Label(
                text: "Stay Focused!",
                color: darkTextColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is blocked during your focus session.",
                color: darkTextColor
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Back to Work",
                color: .white
            ),
            primaryButtonBackgroundColor: sageColor,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "End Session",
                color: redColor
            )
        )
    }

    private func createTimeScheduleShield() -> ShieldConfiguration {
        // Get schedule info for end time
        var subtitleText = "This app is blocked during your scheduled time."

        if let scheduleId = SharedDataManager.shared.activeScheduleId {
            let schedules = SharedDataManager.shared.loadSchedules()
            if let schedule = schedules.first(where: { $0.id == scheduleId }) {
                subtitleText = "Blocked until \(formatTime(hour: schedule.endHour, minute: schedule.endMinute))"
            }
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .light,
            backgroundColor: creamColor,
            icon: nil,
            title: ShieldConfiguration.Label(
                text: "Scheduled Block",
                color: darkTextColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: darkTextColor
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .white
            ),
            primaryButtonBackgroundColor: sageColor,
            secondaryButtonLabel: nil  // No bypass option for scheduled blocks
        )
    }

    private func createUsageLimitShield() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .light,
            backgroundColor: creamColor,
            icon: nil,
            title: ShieldConfiguration.Label(
                text: "Daily Limit Reached",
                color: darkTextColor
            ),
            subtitle: ShieldConfiguration.Label(
                text: "You've used all your allotted time for this app today.",
                color: darkTextColor
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .white
            ),
            primaryButtonBackgroundColor: sageColor,
            secondaryButtonLabel: nil  // No bypass option for usage limits
        )
    }

    private func formatTime(hour: Int, minute: Int) -> String {
        let isPM = hour >= 12
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let suffix = isPM ? "PM" : "AM"

        if minute == 0 {
            return "\(displayHour) \(suffix)"
        } else {
            return String(format: "%d:%02d %@", displayHour, minute, suffix)
        }
    }
}
