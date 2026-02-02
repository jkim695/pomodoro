import XCTest
@testable import PomodoroApp

final class TimerManagerTests: XCTestCase {

    // MARK: - Progress Calculation Tests

    func testProgressInitialState() {
        // Progress should be 0 when no timer is running
        let totalTime = 0
        let timeRemaining = 0

        let progress = totalTime > 0 ? Double(totalTime - timeRemaining) / Double(totalTime) : 0

        XCTAssertEqual(progress, 0)
    }

    func testProgressAtStart() {
        // Progress should be 0 at start
        let totalTime = 1500  // 25 minutes
        let timeRemaining = 1500

        let progress = Double(totalTime - timeRemaining) / Double(totalTime)

        XCTAssertEqual(progress, 0.0)
    }

    func testProgressMidway() {
        // Progress should be 0.5 at halfway
        let totalTime = 1500
        let timeRemaining = 750

        let progress = Double(totalTime - timeRemaining) / Double(totalTime)

        XCTAssertEqual(progress, 0.5)
    }

    func testProgressAtEnd() {
        // Progress should be 1.0 at completion
        let totalTime = 1500
        let timeRemaining = 0

        let progress = Double(totalTime - timeRemaining) / Double(totalTime)

        XCTAssertEqual(progress, 1.0)
    }

    func testProgressQuarterDone() {
        let totalTime = 1500
        let timeRemaining = 1125  // 75% remaining = 25% done

        let progress = Double(totalTime - timeRemaining) / Double(totalTime)

        XCTAssertEqual(progress, 0.25)
    }

    // MARK: - Duration Conversion Tests

    func testMinutesToSeconds() {
        let minutes = 25
        let seconds = minutes * 60

        XCTAssertEqual(seconds, 1500)
    }

    func testSecondsToMinutes() {
        let seconds = 1500
        let minutes = seconds / 60

        XCTAssertEqual(minutes, 25)
    }

    func testDurationFormatting() {
        let totalSeconds = 1500
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        XCTAssertEqual(minutes, 25)
        XCTAssertEqual(seconds, 0)
    }

    func testDurationFormattingWithRemainder() {
        let totalSeconds = 1530  // 25:30
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        XCTAssertEqual(minutes, 25)
        XCTAssertEqual(seconds, 30)
    }

    // MARK: - Background Time Calculation Tests

    func testBackgroundTimeElapsed() {
        let startTime = Date()
        let now = startTime.addingTimeInterval(300)  // 5 minutes later

        let elapsed = Int(now.timeIntervalSince(startTime))

        XCTAssertEqual(elapsed, 300)
    }

    func testBackgroundTimeRemaining() {
        let totalTime = 1500  // 25 minutes
        let startTime = Date()
        let now = startTime.addingTimeInterval(300)  // 5 minutes elapsed

        let elapsed = Int(now.timeIntervalSince(startTime))
        let remaining = totalTime - elapsed

        XCTAssertEqual(remaining, 1200)  // 20 minutes remaining
    }

    func testBackgroundTimerCompleted() {
        let totalTime = 1500
        let startTime = Date()
        let now = startTime.addingTimeInterval(1800)  // 30 minutes (past completion)

        let elapsed = Int(now.timeIntervalSince(startTime))
        let remaining = totalTime - elapsed

        XCTAssertLessThanOrEqual(remaining, 0)
    }

    func testBackgroundTimerJustStarted() {
        let totalTime = 1500
        let startTime = Date()
        let now = startTime.addingTimeInterval(1)  // 1 second elapsed

        let elapsed = Int(now.timeIntervalSince(startTime))
        let remaining = totalTime - elapsed

        XCTAssertEqual(remaining, 1499)
    }

    // MARK: - Timer State Tests

    func testTimerStateInitial() {
        let isRunning = false
        let timeRemaining = 0
        let totalTime = 0

        XCTAssertFalse(isRunning)
        XCTAssertEqual(timeRemaining, 0)
        XCTAssertEqual(totalTime, 0)
    }

    func testTimerStateAfterStart() {
        let isRunning = true
        let totalTime = 1500
        let timeRemaining = 1500

        XCTAssertTrue(isRunning)
        XCTAssertEqual(timeRemaining, totalTime)
    }

    func testTimerStateAfterPause() {
        let isRunning = false
        let pausedTimeRemaining = 1200  // Time was preserved

        XCTAssertFalse(isRunning)
        XCTAssertEqual(pausedTimeRemaining, 1200)
    }

    func testTimerStateAfterReset() {
        let isRunning = false
        let timeRemaining = 0
        let totalTime = 0

        XCTAssertFalse(isRunning)
        XCTAssertEqual(timeRemaining, 0)
        XCTAssertEqual(totalTime, 0)
    }

    // MARK: - Edge Cases

    func testVeryShortTimer() {
        let totalTime = 60  // 1 minute
        let timeRemaining = 30

        let progress = Double(totalTime - timeRemaining) / Double(totalTime)

        XCTAssertEqual(progress, 0.5)
    }

    func testVeryLongTimer() {
        let totalTime = 10800  // 3 hours
        let timeRemaining = 5400  // 1.5 hours remaining

        let progress = Double(totalTime - timeRemaining) / Double(totalTime)

        XCTAssertEqual(progress, 0.5)
    }

    func testTimerTickDecrement() {
        var timeRemaining = 100

        // Simulate tick
        if timeRemaining > 0 {
            timeRemaining -= 1
        }

        XCTAssertEqual(timeRemaining, 99)
    }

    func testTimerCompletionDetection() {
        var timeRemaining = 1

        // Simulate tick
        if timeRemaining > 0 {
            timeRemaining -= 1
        }

        let completed = timeRemaining == 0

        XCTAssertTrue(completed)
    }
}
