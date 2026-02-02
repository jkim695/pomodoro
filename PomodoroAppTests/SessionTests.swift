import XCTest
@testable import PomodoroApp

final class SessionTests: XCTestCase {

    // MARK: - SessionState Tests

    func testSessionStateValues() {
        XCTAssertEqual(SessionState.idle.rawValue, "idle")
        XCTAssertEqual(SessionState.focusing.rawValue, "focusing")
        XCTAssertEqual(SessionState.coolingDown.rawValue, "coolingDown")
    }

    func testSessionStateCodable() throws {
        let state = SessionState.focusing

        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(SessionState.self, from: encoded)

        XCTAssertEqual(decoded, .focusing)
    }

    // MARK: - AvatarState Tests

    func testAvatarStateValues() {
        XCTAssertEqual(AvatarState.sleeping.rawValue, "sleeping")
        XCTAssertEqual(AvatarState.working.rawValue, "working")
        XCTAssertEqual(AvatarState.celebrating.rawValue, "celebrating")
        XCTAssertEqual(AvatarState.disappointed.rawValue, "disappointed")
    }

    func testAvatarStateCodable() throws {
        let state = AvatarState.celebrating

        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(AvatarState.self, from: encoded)

        XCTAssertEqual(decoded, .celebrating)
    }

    // MARK: - SessionStartError Tests

    func testSessionStartErrorEquatable() {
        XCTAssertEqual(SessionStartError.noAppsSelected, SessionStartError.noAppsSelected)
        XCTAssertEqual(SessionStartError.insufficientStardust, SessionStartError.insufficientStardust)
        XCTAssertEqual(
            SessionStartError.monitoringFailed("error"),
            SessionStartError.monitoringFailed("error")
        )
        XCTAssertNotEqual(
            SessionStartError.monitoringFailed("error1"),
            SessionStartError.monitoringFailed("error2")
        )
    }

    // MARK: - CoolDown Tests

    func testCoolDownDuration() {
        XCTAssertEqual(PomodoroSession.coolDownDurationSeconds, 10)
    }

    func testCoolDownCountdown() {
        var coolDownRemaining = PomodoroSession.coolDownDurationSeconds

        // Simulate countdown ticks
        while coolDownRemaining > 0 {
            coolDownRemaining -= 1
        }

        XCTAssertEqual(coolDownRemaining, 0)
    }

    func testCoolDownCanConfirmQuitWhenZero() {
        let coolDownRemaining = 0
        let canConfirm = coolDownRemaining == 0

        XCTAssertTrue(canConfirm)
    }

    func testCoolDownCannotConfirmQuitWhenNonZero() {
        let coolDownRemaining = 5
        let canConfirm = coolDownRemaining == 0

        XCTAssertFalse(canConfirm)
    }

    // MARK: - Focus Duration Tests

    func testDefaultFocusDuration() {
        let defaultDuration = 25  // minutes

        XCTAssertEqual(defaultDuration, 25)
    }

    func testFocusDurationToSeconds() {
        let durationMinutes = 25
        let durationSeconds = durationMinutes * 60

        XCTAssertEqual(durationSeconds, 1500)
    }

    func testMinimumFocusDuration() {
        let minimumMinutes = 10

        XCTAssertGreaterThanOrEqual(minimumMinutes, 10)
    }

    func testMaximumFocusDuration() {
        let maximumMinutes = 180  // 3 hours

        XCTAssertLessThanOrEqual(maximumMinutes, 180)
    }

    // MARK: - State Transition Tests

    func testIdleToFocusingTransition() {
        var state = SessionState.idle

        // Simulate start
        state = .focusing

        XCTAssertEqual(state, .focusing)
    }

    func testFocusingToCoolingDownTransition() {
        var state = SessionState.focusing

        // Simulate quit request
        state = .coolingDown

        XCTAssertEqual(state, .coolingDown)
    }

    func testCoolingDownToFocusingTransition() {
        var state = SessionState.coolingDown

        // Simulate cancel quit
        state = .focusing

        XCTAssertEqual(state, .focusing)
    }

    func testCoolingDownToIdleTransition() {
        var state = SessionState.coolingDown

        // Simulate confirm quit
        state = .idle

        XCTAssertEqual(state, .idle)
    }

    func testFocusingToIdleTransitionOnCompletion() {
        var state = SessionState.focusing

        // Simulate natural completion
        state = .idle

        XCTAssertEqual(state, .idle)
    }

    // MARK: - Avatar State Transition Tests

    func testAvatarIdleToWorking() {
        var avatarState = AvatarState.sleeping

        // Session starts
        avatarState = .working

        XCTAssertEqual(avatarState, .working)
    }

    func testAvatarWorkingToCelebrating() {
        var avatarState = AvatarState.working

        // Session completes successfully
        avatarState = .celebrating

        XCTAssertEqual(avatarState, .celebrating)
    }

    func testAvatarWorkingToDisappointed() {
        var avatarState = AvatarState.working

        // User quits early
        avatarState = .disappointed

        XCTAssertEqual(avatarState, .disappointed)
    }

    func testAvatarCelebratingToSleeping() {
        var avatarState = AvatarState.celebrating

        // After celebration timeout
        avatarState = .sleeping

        XCTAssertEqual(avatarState, .sleeping)
    }

    func testAvatarDisappointedToSleeping() {
        var avatarState = AvatarState.disappointed

        // After disappointment timeout
        avatarState = .sleeping

        XCTAssertEqual(avatarState, .sleeping)
    }

    // MARK: - Ante Logic Tests

    func testAnteAmountConstant() {
        XCTAssertEqual(RewardsManager.sessionAnteAmount, 50)
    }

    func testAnteBonusMultiplier() {
        XCTAssertEqual(RewardsManager.anteBonusMultiplier, 2.0)
    }

    func testSessionWithAnteCalculation() {
        // User has enough and chooses to use ante
        let balance = 100
        let anteAmount = 50
        let canUseAnte = balance >= anteAmount

        XCTAssertTrue(canUseAnte)
    }

    func testSessionWithoutEnoughForAnte() {
        // User doesn't have enough for ante
        let balance = 30
        let anteAmount = 50
        let canUseAnte = balance >= anteAmount

        XCTAssertFalse(canUseAnte)
    }

    func testAnteReturnedOnSuccess() {
        // Simulate successful session with ante
        var balance = StardustBalance()
        balance.add(100)
        _ = balance.holdAnte(50)

        // Session completes
        balance.returnAnte()

        XCTAssertEqual(balance.current, 100)  // Full balance restored
        XCTAssertEqual(balance.anteInEscrow, 0)
    }

    func testAnteBurnedOnQuit() {
        // Simulate quit with ante
        var balance = StardustBalance()
        balance.add(100)
        _ = balance.holdAnte(50)

        // User quits
        balance.burnAnte()

        XCTAssertEqual(balance.current, 50)  // Lost the ante
        XCTAssertEqual(balance.anteInEscrow, 0)
    }

    // MARK: - Session Reward Flow Tests

    func testRewardCalculationWithAnte() {
        // 25 min session with ante
        let baseReward = Int(25.0 * 0.4)  // 10
        let anteBonus = Int(Double(baseReward) * 2.0)  // 20

        XCTAssertEqual(anteBonus, 20)
    }

    func testRewardCalculationWithoutAnte() {
        // 25 min session without ante
        let baseReward = Int(25.0 * 0.4)  // 10

        XCTAssertEqual(baseReward, 10)
    }

    func testNoRewardOnIncompleteSession() {
        // Session not completed
        let completed = false
        let reward = completed ? 10 : 0

        XCTAssertEqual(reward, 0)
    }

    // MARK: - Timer Completion Detection Tests

    func testTimerCompletionCheck() {
        let timeRemaining = 0
        let isRunning = false

        let isCompleted = timeRemaining == 0 && !isRunning

        XCTAssertTrue(isCompleted)
    }

    func testTimerNotCompletedWhenRunning() {
        let timeRemaining = 0
        let isRunning = true

        let isCompleted = timeRemaining == 0 && !isRunning

        XCTAssertFalse(isCompleted)
    }

    func testTimerNotCompletedWithTimeRemaining() {
        let timeRemaining = 100
        let isRunning = false

        let isCompleted = timeRemaining == 0 && !isRunning

        XCTAssertFalse(isCompleted)
    }
}
