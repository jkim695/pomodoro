import Foundation

/// Tracks daily usage for a specific app limit
struct UsageRecord: Codable, Identifiable {
    var id: UUID { limitId }
    let limitId: UUID
    var date: Date          // Date normalized to start of day
    var usedSeconds: Int    // Total seconds used today
    var lastUpdated: Date

    init(
        limitId: UUID,
        date: Date = Calendar.current.startOfDay(for: Date()),
        usedSeconds: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.limitId = limitId
        self.date = date
        self.usedSeconds = usedSeconds
        self.lastUpdated = lastUpdated
    }

    /// Used minutes (rounded)
    var usedMinutes: Int {
        usedSeconds / 60
    }

    /// Progress towards limit (0.0 to 1.0+)
    func progress(limitMinutes: Int) -> Double {
        guard limitMinutes > 0 else { return 0 }
        return Double(usedMinutes) / Double(limitMinutes)
    }

    /// Remaining minutes
    func remainingMinutes(limitMinutes: Int) -> Int {
        max(0, limitMinutes - usedMinutes)
    }

    /// Whether the limit has been reached
    func isLimitReached(limitMinutes: Int) -> Bool {
        usedMinutes >= limitMinutes
    }

    /// Formatted used time string
    var formattedUsedTime: String {
        AppLimit.formatMinutes(usedMinutes)
    }

    /// Check if this record should be reset based on the reset hour
    func shouldReset(resetHour: Int) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // Get the reset time for today
        var resetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        resetComponents.hour = resetHour
        resetComponents.minute = 0
        resetComponents.second = 0

        guard let todayResetTime = calendar.date(from: resetComponents) else {
            return false
        }

        // If current time is past reset time and last update was before reset time
        if now >= todayResetTime && lastUpdated < todayResetTime {
            return true
        }

        // If the record is from a previous day
        let recordDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: now)
        if recordDay < today && now >= todayResetTime {
            return true
        }

        return false
    }

    /// Create a reset copy of this record
    func reset() -> UsageRecord {
        UsageRecord(
            limitId: limitId,
            date: Calendar.current.startOfDay(for: Date()),
            usedSeconds: 0,
            lastUpdated: Date()
        )
    }
}

/// Encapsulates all usage records for persistence
struct UsageRecordStore: Codable {
    var records: [UUID: UsageRecord]

    init(records: [UUID: UsageRecord] = [:]) {
        self.records = records
    }

    /// Get or create a record for a limit
    mutating func getOrCreate(for limitId: UUID) -> UsageRecord {
        if let existing = records[limitId] {
            return existing
        }
        let newRecord = UsageRecord(limitId: limitId)
        records[limitId] = newRecord
        return newRecord
    }

    /// Update usage for a limit
    mutating func addUsage(for limitId: UUID, seconds: Int) {
        var record = getOrCreate(for: limitId)
        record.usedSeconds += seconds
        record.lastUpdated = Date()
        records[limitId] = record
    }

    /// Reset a specific record
    mutating func reset(limitId: UUID) {
        if var record = records[limitId] {
            record = record.reset()
            records[limitId] = record
        }
    }

    /// Reset records that need resetting based on their limits' reset hours
    mutating func resetIfNeeded(limits: [AppLimit]) {
        for limit in limits {
            if let record = records[limit.id], record.shouldReset(resetHour: limit.resetHour) {
                records[limit.id] = record.reset()
            }
        }
    }

    /// Remove records for limits that no longer exist
    mutating func cleanup(existingLimitIds: Set<UUID>) {
        records = records.filter { existingLimitIds.contains($0.key) }
    }
}
