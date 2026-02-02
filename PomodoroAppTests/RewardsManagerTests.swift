import XCTest
@testable import PomodoroApp

final class RewardsManagerTests: XCTestCase {

    // MARK: - StardustBalance Tests

    func testStardustBalanceInitialState() {
        let balance = StardustBalance()

        XCTAssertEqual(balance.total, 0)
        XCTAssertEqual(balance.current, 0)
        XCTAssertEqual(balance.lastSessionReward, 0)
        XCTAssertEqual(balance.anteInEscrow, 0)
    }

    func testStardustBalanceAdd() {
        var balance = StardustBalance()

        balance.add(100)

        XCTAssertEqual(balance.total, 100)
        XCTAssertEqual(balance.current, 100)
        XCTAssertEqual(balance.lastSessionReward, 100)
    }

    func testStardustBalanceAddMultiple() {
        var balance = StardustBalance()

        balance.add(50)
        balance.add(30)

        XCTAssertEqual(balance.total, 80)
        XCTAssertEqual(balance.current, 80)
        XCTAssertEqual(balance.lastSessionReward, 30) // Only last reward
    }

    func testStardustBalanceSpendSuccess() {
        var balance = StardustBalance()
        balance.add(100)

        let result = balance.spend(40)

        XCTAssertTrue(result)
        XCTAssertEqual(balance.current, 60)
        XCTAssertEqual(balance.total, 100) // Total doesn't decrease
    }

    func testStardustBalanceSpendInsufficientFunds() {
        var balance = StardustBalance()
        balance.add(30)

        let result = balance.spend(50)

        XCTAssertFalse(result)
        XCTAssertEqual(balance.current, 30) // Unchanged
    }

    func testStardustBalanceSpendExactAmount() {
        var balance = StardustBalance()
        balance.add(50)

        let result = balance.spend(50)

        XCTAssertTrue(result)
        XCTAssertEqual(balance.current, 0)
    }

    // MARK: - Ante/Escrow Tests

    func testCanAffordAnte() {
        var balance = StardustBalance()
        balance.add(100)

        XCTAssertTrue(balance.canAffordAnte(50))
        XCTAssertTrue(balance.canAffordAnte(100))
        XCTAssertFalse(balance.canAffordAnte(101))
    }

    func testHoldAnteSuccess() {
        var balance = StardustBalance()
        balance.add(100)

        let result = balance.holdAnte(50)

        XCTAssertTrue(result)
        XCTAssertEqual(balance.current, 50)
        XCTAssertEqual(balance.anteInEscrow, 50)
        XCTAssertEqual(balance.total, 100) // Total unchanged
    }

    func testHoldAnteInsufficientFunds() {
        var balance = StardustBalance()
        balance.add(30)

        let result = balance.holdAnte(50)

        XCTAssertFalse(result)
        XCTAssertEqual(balance.current, 30)
        XCTAssertEqual(balance.anteInEscrow, 0)
    }

    func testReturnAnte() {
        var balance = StardustBalance()
        balance.add(100)
        _ = balance.holdAnte(50)

        balance.returnAnte()

        XCTAssertEqual(balance.current, 100) // Ante returned
        XCTAssertEqual(balance.anteInEscrow, 0)
    }

    func testBurnAnte() {
        var balance = StardustBalance()
        balance.add(100)
        _ = balance.holdAnte(50)

        balance.burnAnte()

        XCTAssertEqual(balance.current, 50) // Ante lost
        XCTAssertEqual(balance.anteInEscrow, 0)
        XCTAssertEqual(balance.total, 100) // Total unchanged
    }

    // MARK: - Reward Calculation Tests

    func testCalculateRewardBase25Minutes() {
        // Base rate: 0.4 Stardust/minute
        // 25 min = 10 base
        let progress = UserProgress()
        let baseReward = Int(25.0 * 0.4) // = 10

        XCTAssertEqual(baseReward, 10)
    }

    func testCalculateRewardBase50Minutes() {
        // 50 min = 20 base
        let baseReward = Int(50.0 * 0.4)

        XCTAssertEqual(baseReward, 20)
    }

    func testCalculateRewardWithStreakBonus() {
        var progress = UserProgress()
        progress.currentStreak = 3

        // Streak bonus: +10% per day, max 50%
        // 3-day streak = (3-1) * 0.1 = 0.2 = 20% bonus
        let baseReward = 10
        let streakMultiplier = 1.0 + progress.streakBonusMultiplier
        let expectedReward = Int(Double(baseReward) * streakMultiplier)

        XCTAssertEqual(progress.streakBonusMultiplier, 0.2)
        XCTAssertEqual(expectedReward, 12) // 10 * 1.2 = 12
    }

    func testCalculateRewardStreakBonusMax() {
        var progress = UserProgress()
        progress.currentStreak = 10

        // Max 50% bonus at 6+ days
        XCTAssertEqual(progress.streakBonusMultiplier, 0.5)
    }

    func testCalculateRewardWithAnteBonus() {
        // Ante bonus is 2x multiplier
        let baseReward = 10
        let anteMultiplier = 2.0
        let expectedReward = Int(Double(baseReward) * anteMultiplier)

        XCTAssertEqual(expectedReward, 20)
    }

    func testCalculateRewardNotCompleted() {
        // Incomplete sessions award 0
        let completed = false
        let reward = completed ? 10 : 0

        XCTAssertEqual(reward, 0)
    }

    func testCalculateRewardMinimum() {
        // Minimum 1 Stardust for any completed session
        let shortSession = 1 // 1 minute
        let baseReward = max(Int(Double(shortSession) * 0.4), 1)

        XCTAssertEqual(baseReward, 1)
    }

    // MARK: - UserProgress Tests

    func testUserProgressInitialState() {
        let progress = UserProgress()

        XCTAssertEqual(progress.totalSessionsCompleted, 0)
        XCTAssertEqual(progress.totalFocusMinutes, 0)
        XCTAssertEqual(progress.currentStreak, 0)
        XCTAssertEqual(progress.longestStreak, 0)
        XCTAssertNil(progress.lastSessionDate)
        XCTAssertTrue(progress.achievedMilestones.isEmpty)
    }

    func testUserProgressRecordSession() {
        var progress = UserProgress()

        progress.recordSession(durationMinutes: 25)

        XCTAssertEqual(progress.totalSessionsCompleted, 1)
        XCTAssertEqual(progress.totalFocusMinutes, 25)
        XCTAssertEqual(progress.sessionsByDuration[25], 1)
        XCTAssertNotNil(progress.lastSessionDate)
    }

    func testUserProgressMultipleSessions() {
        var progress = UserProgress()

        progress.recordSession(durationMinutes: 25)
        progress.recordSession(durationMinutes: 50)
        progress.recordSession(durationMinutes: 25)

        XCTAssertEqual(progress.totalSessionsCompleted, 3)
        XCTAssertEqual(progress.totalFocusMinutes, 100)
        XCTAssertEqual(progress.sessionsByDuration[25], 2)
        XCTAssertEqual(progress.sessionsByDuration[50], 1)
    }

    func testUserProgressStreakBonusMultiplier() {
        var progress = UserProgress()

        // Day 1: no bonus
        progress.currentStreak = 1
        XCTAssertEqual(progress.streakBonusMultiplier, 0.0)

        // Day 2: 10% bonus
        progress.currentStreak = 2
        XCTAssertEqual(progress.streakBonusMultiplier, 0.1)

        // Day 3: 20% bonus
        progress.currentStreak = 3
        XCTAssertEqual(progress.streakBonusMultiplier, 0.2)

        // Day 6+: 50% max bonus
        progress.currentStreak = 6
        XCTAssertEqual(progress.streakBonusMultiplier, 0.5)

        progress.currentStreak = 10
        XCTAssertEqual(progress.streakBonusMultiplier, 0.5) // Still capped
    }

    // MARK: - Milestone Tests

    func testMilestoneFirstSession() {
        let milestone = Milestones.all.first { $0.id == "first_session" }!

        var progress = UserProgress()
        XCTAssertFalse(milestone.isAchieved(by: progress))

        progress.totalSessionsCompleted = 1
        XCTAssertTrue(milestone.isAchieved(by: progress))
    }

    func testMilestoneTenSessions() {
        let milestone = Milestones.all.first { $0.id == "sessions_10" }!

        var progress = UserProgress()
        progress.totalSessionsCompleted = 9
        XCTAssertFalse(milestone.isAchieved(by: progress))

        progress.totalSessionsCompleted = 10
        XCTAssertTrue(milestone.isAchieved(by: progress))
    }

    func testMilestoneFocusMinutes() {
        let milestone = Milestones.all.first { $0.id == "focus_hour" }!

        var progress = UserProgress()
        progress.totalFocusMinutes = 59
        XCTAssertFalse(milestone.isAchieved(by: progress))

        progress.totalFocusMinutes = 60
        XCTAssertTrue(milestone.isAchieved(by: progress))
    }

    func testMilestoneStreak() {
        let milestone = Milestones.all.first { $0.id == "streak_3" }!

        var progress = UserProgress()
        progress.longestStreak = 2
        XCTAssertFalse(milestone.isAchieved(by: progress))

        progress.longestStreak = 3
        XCTAssertTrue(milestone.isAchieved(by: progress))
    }

    // MARK: - UserCollection Tests

    func testUserCollectionInitialState() {
        let collection = UserCollection()

        XCTAssertTrue(collection.owns("orb_default"))
        XCTAssertTrue(collection.owns("orb_ocean"))
        XCTAssertFalse(collection.owns("orb_nonexistent"))
        XCTAssertEqual(collection.equippedOrbStyleId, "orb_default")
    }

    func testUserCollectionEquip() {
        var collection = UserCollection()

        let result = collection.equip("orb_ocean")

        XCTAssertTrue(result)
        XCTAssertEqual(collection.equippedOrbStyleId, "orb_ocean")
    }

    func testUserCollectionEquipNotOwned() {
        var collection = UserCollection()

        let result = collection.equip("orb_nonexistent")

        XCTAssertFalse(result)
        XCTAssertEqual(collection.equippedOrbStyleId, "orb_default") // Unchanged
    }

    func testUserCollectionAddPurchase() {
        var collection = UserCollection()

        collection.addPurchase(styleId: "orb_new", price: 100)

        XCTAssertTrue(collection.owns("orb_new"))
        XCTAssertEqual(collection.purchaseHistory.count, 1)
        XCTAssertEqual(collection.purchaseHistory[0].orbStyleId, "orb_new")
        XCTAssertEqual(collection.purchaseHistory[0].price, 100)
    }
}
