import Foundation
import os.log

/// Centralized logging utility using Apple's unified logging system.
/// Logs can be filtered in Console.app by subsystem and category.
enum AppLogger {
    /// Subsystem identifier for all app logs
    private static let subsystem = "com.orchard.app"

    // MARK: - Logger Categories

    /// Logger for session-related events (timer, focus sessions)
    static let session = Logger(subsystem: subsystem, category: "session")

    /// Logger for rewards system events (stardust, gacha, collection)
    static let rewards = Logger(subsystem: subsystem, category: "rewards")

    /// Logger for shield/blocking events
    static let shield = Logger(subsystem: subsystem, category: "shield")

    /// Logger for general app events (lifecycle, errors)
    static let general = Logger(subsystem: subsystem, category: "general")

    /// Logger for data persistence events
    static let data = Logger(subsystem: subsystem, category: "data")

    /// Logger for notification events
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
}
