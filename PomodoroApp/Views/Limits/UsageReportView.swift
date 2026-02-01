import SwiftUI
import DeviceActivity
import FamilyControls

/// Report context for displaying usage data
extension DeviceActivityReport.Context {
    /// Context for showing total usage across all limited apps
    static let totalUsage = Self("totalUsage")

    /// Context for showing individual app usage breakdown
    static let appUsage = Self("appUsage")
}

/// A view that displays actual Screen Time usage data for limited apps
struct UsageReportView: View {
    let selection: FamilyActivitySelection

    @State private var filter: DeviceActivityFilter

    init(selection: FamilyActivitySelection) {
        self.selection = selection

        // Create filter for today's usage of selected apps
        let calendar = Calendar.current
        let now = Date()
        let todayInterval = calendar.dateInterval(of: .day, for: now) ?? DateInterval(start: now, end: now)

        _filter = State(initialValue: DeviceActivityFilter(
            segment: .daily(during: todayInterval),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: selection.applicationTokens,
            categories: selection.categoryTokens
        ))
    }

    var body: some View {
        DeviceActivityReport(.totalUsage, filter: filter)
            .frame(minHeight: 80)
    }
}

/// A compact usage display that shows time used today
struct CompactUsageReportView: View {
    let selection: FamilyActivitySelection
    let limitMinutes: Int

    @State private var filter: DeviceActivityFilter

    init(selection: FamilyActivitySelection, limitMinutes: Int) {
        self.selection = selection
        self.limitMinutes = limitMinutes

        let calendar = Calendar.current
        let now = Date()
        let todayInterval = calendar.dateInterval(of: .day, for: now) ?? DateInterval(start: now, end: now)

        _filter = State(initialValue: DeviceActivityFilter(
            segment: .daily(during: todayInterval),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: selection.applicationTokens,
            categories: selection.categoryTokens
        ))
    }

    var body: some View {
        DeviceActivityReport(.totalUsage, filter: filter)
            .frame(height: 100)
    }
}
