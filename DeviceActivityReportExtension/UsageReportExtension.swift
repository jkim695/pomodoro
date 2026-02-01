import DeviceActivity
import SwiftUI
import FamilyControls
import ManagedSettings

/// Extension that provides Screen Time usage reports for the Limits feature
/// NOTE: This extension CANNOT write to App Groups due to iOS privacy sandbox.
/// Usage tracking for progress bars is done via DeviceActivityMonitor instead.
@main
struct UsageReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Total usage report for all monitored apps
        TotalUsageReport { totalActivity in
            TotalUsageView(activityReport: totalActivity)
        }

        // Individual app usage details
        AppUsageReport { activityReport in
            AppUsageView(activityReport: activityReport)
        }
    }
}

// MARK: - Report Context Definitions

extension DeviceActivityReport.Context {
    /// Context for showing total usage across all limited apps
    static let totalUsage = Self("totalUsage")

    /// Context for showing individual app usage breakdown
    static let appUsage = Self("appUsage")
}

// MARK: - Total Usage Report

struct TotalUsageReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalUsage

    let content: (ActivityReport) -> TotalUsageView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
        var totalDuration: TimeInterval = 0
        var appUsages: [AppUsageInfo] = []

        // Process activity data - iterate through the async sequence
        for await activityData in data {
            let segments = activityData.activitySegments

            for await segment in segments {
                totalDuration += segment.totalActivityDuration

                // Get app activities from the segment
                for await appActivity in segment.categories {
                    for await app in appActivity.applications {
                        let appInfo = AppUsageInfo(
                            displayName: app.application.localizedDisplayName ?? "App",
                            duration: app.totalActivityDuration
                        )
                        if let existingIndex = appUsages.firstIndex(where: { $0.displayName == appInfo.displayName }) {
                            appUsages[existingIndex].duration += appInfo.duration
                        } else {
                            appUsages.append(appInfo)
                        }
                    }
                }
            }
        }

        // Sort by duration descending
        appUsages.sort { $0.duration > $1.duration }

        return ActivityReport(totalDuration: totalDuration, apps: appUsages)
    }
}

// MARK: - App Usage Report

struct AppUsageReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .appUsage

    let content: (ActivityReport) -> AppUsageView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityReport {
        var appUsages: [AppUsageInfo] = []

        for await activityData in data {
            let segments = activityData.activitySegments

            for await segment in segments {
                for await categoryActivity in segment.categories {
                    for await app in categoryActivity.applications {
                        let appInfo = AppUsageInfo(
                            displayName: app.application.localizedDisplayName ?? "App",
                            duration: app.totalActivityDuration
                        )
                        if let existingIndex = appUsages.firstIndex(where: { $0.displayName == appInfo.displayName }) {
                            appUsages[existingIndex].duration += appInfo.duration
                        } else {
                            appUsages.append(appInfo)
                        }
                    }
                }
            }
        }

        appUsages.sort { $0.duration > $1.duration }

        return ActivityReport(totalDuration: appUsages.reduce(0) { $0 + $1.duration }, apps: appUsages)
    }
}

// MARK: - Data Models

struct ActivityReport {
    let totalDuration: TimeInterval
    let apps: [AppUsageInfo]

    var formattedTotalDuration: String {
        formatDuration(totalDuration)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct AppUsageInfo: Identifiable {
    let id = UUID()
    let displayName: String
    var duration: TimeInterval

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1m"
        }
    }
}

// MARK: - SwiftUI Views

struct TotalUsageView: View {
    let activityReport: ActivityReport

    var body: some View {
        VStack(spacing: 8) {
            // Total time header
            HStack {
                Text("Today's Usage")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 139/255, green: 119/255, blue: 101/255))

                Spacer()

                Text(activityReport.formattedTotalDuration)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 92/255, green: 64/255, blue: 51/255))
            }

            // Top apps list
            if !activityReport.apps.isEmpty {
                VStack(spacing: 6) {
                    ForEach(activityReport.apps.prefix(5)) { app in
                        HStack {
                            Text(app.displayName)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(Color(red: 92/255, green: 64/255, blue: 51/255))
                                .lineLimit(1)

                            Spacer()

                            Text(app.formattedDuration)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 139/255, green: 119/255, blue: 101/255))
                        }
                    }
                }
            } else {
                Text("No usage recorded today")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Color(red: 139/255, green: 119/255, blue: 101/255))
            }
        }
        .padding(12)
        .background(Color(red: 255/255, green: 248/255, blue: 231/255))
        .cornerRadius(12)
    }
}

struct AppUsageView: View {
    let activityReport: ActivityReport

    var body: some View {
        VStack(spacing: 8) {
            ForEach(activityReport.apps) { app in
                HStack {
                    Text(app.displayName)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(Color(red: 92/255, green: 64/255, blue: 51/255))
                        .lineLimit(1)

                    Spacer()

                    Text(app.formattedDuration)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 255/255, green: 203/255, blue: 164/255))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(Color(red: 255/255, green: 248/255, blue: 231/255))
        .cornerRadius(12)
    }
}
