import Foundation
import SwiftUI
import FamilyControls
import Combine

/// Central state manager for the App Limits feature
/// Coordinates schedules, limits, and their monitoring
@MainActor
final class LimitsSession: ObservableObject {
    @Published var schedules: [TimeSchedule] = []
    @Published var limits: [AppLimit] = []
    @Published var usageRecords: UsageRecordStore = UsageRecordStore()
    @Published var error: String?

    private let scheduler = LimitsScheduler.shared
    private let shieldManager = LimitsShieldManager.shared
    private let sharedData = SharedDataManager.shared

    init() {
        // Load saved data
        schedules = sharedData.loadSchedules()
        limits = sharedData.loadLimits()
        usageRecords = sharedData.loadUsageRecords()

        // Reset usage records if needed (e.g., new day)
        usageRecords.resetIfNeeded(limits: limits)
        sharedData.saveUsageRecords(usageRecords)

        // Sync active monitoring with saved enabled state
        scheduler.syncAll()
    }

    // MARK: - Time Schedules

    /// Adds a new time schedule
    func addSchedule(_ schedule: TimeSchedule) {
        schedules.append(schedule)
        saveSchedules()

        if schedule.isEnabled {
            do {
                try scheduler.startScheduleMonitoring(schedule)
            } catch {
                self.error = "Failed to start schedule: \(error.localizedDescription)"
            }
        }
    }

    /// Updates an existing time schedule
    func updateSchedule(_ schedule: TimeSchedule) {
        guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }

        let wasEnabled = schedules[index].isEnabled
        schedules[index] = schedule
        saveSchedules()

        // Handle monitoring changes
        if wasEnabled && !schedule.isEnabled {
            scheduler.stopScheduleMonitoring(scheduleId: schedule.id)
        } else if schedule.isEnabled {
            // Restart monitoring with updated config
            scheduler.stopScheduleMonitoring(scheduleId: schedule.id)
            do {
                try scheduler.startScheduleMonitoring(schedule)
            } catch {
                self.error = "Failed to update schedule: \(error.localizedDescription)"
            }
        }
    }

    /// Deletes a time schedule
    func deleteSchedule(id: UUID) {
        schedules.removeAll { $0.id == id }
        saveSchedules()
        scheduler.stopScheduleMonitoring(scheduleId: id)
    }

    /// Toggles a schedule's enabled state
    func toggleSchedule(id: UUID, enabled: Bool) {
        guard let index = schedules.firstIndex(where: { $0.id == id }) else { return }

        schedules[index].isEnabled = enabled
        saveSchedules()

        if enabled {
            do {
                try scheduler.startScheduleMonitoring(schedules[index])
            } catch {
                self.error = "Failed to enable schedule: \(error.localizedDescription)"
            }
        } else {
            scheduler.stopScheduleMonitoring(scheduleId: id)
        }
    }

    // MARK: - App Limits

    /// Adds a new app limit
    func addLimit(_ limit: AppLimit) {
        limits.append(limit)
        saveLimits()

        // Initialize usage record
        _ = usageRecords.getOrCreate(for: limit.id)
        sharedData.saveUsageRecords(usageRecords)

        if limit.isEnabled {
            do {
                try scheduler.startUsageMonitoring(limit)
            } catch {
                self.error = "Failed to start limit monitoring: \(error.localizedDescription)"
            }
        }
    }

    /// Updates an existing app limit
    func updateLimit(_ limit: AppLimit) {
        guard let index = limits.firstIndex(where: { $0.id == limit.id }) else { return }

        let wasEnabled = limits[index].isEnabled
        limits[index] = limit
        saveLimits()

        // Handle monitoring changes
        if wasEnabled && !limit.isEnabled {
            scheduler.stopUsageMonitoring(limitId: limit.id)
        } else if limit.isEnabled {
            // Restart monitoring with updated config
            scheduler.stopUsageMonitoring(limitId: limit.id)
            do {
                try scheduler.startUsageMonitoring(limit)
            } catch {
                self.error = "Failed to update limit: \(error.localizedDescription)"
            }
        }
    }

    /// Deletes an app limit
    func deleteLimit(id: UUID) {
        limits.removeAll { $0.id == id }
        saveLimits()
        scheduler.stopUsageMonitoring(limitId: id)

        // Clean up usage record
        usageRecords.records.removeValue(forKey: id)
        sharedData.saveUsageRecords(usageRecords)
    }

    /// Toggles a limit's enabled state
    func toggleLimit(id: UUID, enabled: Bool) {
        guard let index = limits.firstIndex(where: { $0.id == id }) else { return }

        limits[index].isEnabled = enabled
        saveLimits()

        if enabled {
            do {
                try scheduler.startUsageMonitoring(limits[index])
            } catch {
                self.error = "Failed to enable limit: \(error.localizedDescription)"
            }
        } else {
            scheduler.stopUsageMonitoring(limitId: id)
            // Also remove shields if this limit had triggered them
            shieldManager.removeAllShields()
        }
    }

    // MARK: - Usage Tracking

    /// Gets usage record for a specific limit
    func usageRecord(for limitId: UUID) -> UsageRecord? {
        usageRecords.records[limitId]
    }

    /// Gets progress (0.0 to 1.0+) for a specific limit
    func progress(for limitId: UUID) -> Double {
        guard let limit = limits.first(where: { $0.id == limitId }),
              let record = usageRecords.records[limitId] else {
            return 0
        }
        return record.progress(limitMinutes: limit.dailyLimitMinutes)
    }

    /// Refreshes usage records from shared storage (call when app becomes active)
    func refreshUsageRecords() {
        usageRecords = sharedData.loadUsageRecords()
        usageRecords.resetIfNeeded(limits: limits)
        sharedData.saveUsageRecords(usageRecords)
        objectWillChange.send()
    }

    // MARK: - App Lifecycle

    /// Called when app becomes active to sync state
    func handleAppBecameActive() {
        // Refresh usage records (extensions may have updated them)
        refreshUsageRecords()

        // Re-sync schedules in case system state changed
        schedules = sharedData.loadSchedules()
        limits = sharedData.loadLimits()
    }

    // MARK: - Private Methods

    private func saveSchedules() {
        sharedData.saveSchedules(schedules)
    }

    private func saveLimits() {
        sharedData.saveLimits(limits)
    }
}
