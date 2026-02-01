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
}
