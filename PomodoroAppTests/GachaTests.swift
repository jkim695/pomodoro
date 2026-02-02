import XCTest
@testable import PomodoroApp

final class GachaTests: XCTestCase {

    // MARK: - GachaConfig Tests

    func testPullCosts() {
        XCTAssertEqual(GachaConfig.singlePullCost, 15)
        XCTAssertEqual(GachaConfig.tenPullCost, 120)

        // 10-pull should have 20% discount
        let fullPrice = GachaConfig.singlePullCost * 10  // 150
        let discount = Double(fullPrice - GachaConfig.tenPullCost) / Double(fullPrice)
        XCTAssertEqual(discount, 0.2, accuracy: 0.01)
    }

    func testShardsToUnlock() {
        XCTAssertEqual(GachaConfig.shardsToUnlock(rarity: .common), 10)
        XCTAssertEqual(GachaConfig.shardsToUnlock(rarity: .uncommon), 25)
        XCTAssertEqual(GachaConfig.shardsToUnlock(rarity: .rare), 50)
        XCTAssertEqual(GachaConfig.shardsToUnlock(rarity: .epic), 100)
        XCTAssertEqual(GachaConfig.shardsToUnlock(rarity: .legendary), 200)
    }

    func testShardsPerStar() {
        // Same as unlock cost
        XCTAssertEqual(GachaConfig.shardsPerStar(rarity: .common), 10)
        XCTAssertEqual(GachaConfig.shardsPerStar(rarity: .uncommon), 25)
        XCTAssertEqual(GachaConfig.shardsPerStar(rarity: .rare), 50)
        XCTAssertEqual(GachaConfig.shardsPerStar(rarity: .epic), 100)
        XCTAssertEqual(GachaConfig.shardsPerStar(rarity: .legendary), 200)
    }

    func testDropRatesSumTo100() {
        let total = GachaConfig.dropRates.values.reduce(0, +)
        XCTAssertEqual(total, 100.0, accuracy: 0.001)
    }

    func testDropRates() {
        XCTAssertEqual(GachaConfig.dropRates[.common], 50.0)
        XCTAssertEqual(GachaConfig.dropRates[.uncommon], 25.0)
        XCTAssertEqual(GachaConfig.dropRates[.rare], 15.0)
        XCTAssertEqual(GachaConfig.dropRates[.epic], 7.0)
        XCTAssertEqual(GachaConfig.dropRates[.legendary], 3.0)
    }

    func testShardsPerPull() {
        XCTAssertEqual(GachaConfig.shardsPerPull(rarity: .common), 3)
        XCTAssertEqual(GachaConfig.shardsPerPull(rarity: .uncommon), 5)
        XCTAssertEqual(GachaConfig.shardsPerPull(rarity: .rare), 10)
        XCTAssertEqual(GachaConfig.shardsPerPull(rarity: .epic), 20)
        XCTAssertEqual(GachaConfig.shardsPerPull(rarity: .legendary), 40)
    }

    func testPityThresholds() {
        XCTAssertEqual(GachaConfig.pityRare, 30)
        XCTAssertEqual(GachaConfig.pityEpic, 50)
        XCTAssertEqual(GachaConfig.pityLegendary, 100)
    }

    // MARK: - ShardInventory Tests

    func testShardInventoryInitialState() {
        let inventory = ShardInventory()

        XCTAssertEqual(inventory.count(for: "orb_test"), 0)
    }

    func testShardInventoryAdd() {
        var inventory = ShardInventory()

        inventory.add(10, for: "orb_test")

        XCTAssertEqual(inventory.count(for: "orb_test"), 10)
    }

    func testShardInventoryAddMultiple() {
        var inventory = ShardInventory()

        inventory.add(10, for: "orb_test")
        inventory.add(5, for: "orb_test")

        XCTAssertEqual(inventory.count(for: "orb_test"), 15)
    }

    func testShardInventoryConsumeSuccess() {
        var inventory = ShardInventory()
        inventory.add(20, for: "orb_test")

        let result = inventory.consume(10, for: "orb_test")

        XCTAssertTrue(result)
        XCTAssertEqual(inventory.count(for: "orb_test"), 10)
    }

    func testShardInventoryConsumeInsufficient() {
        var inventory = ShardInventory()
        inventory.add(5, for: "orb_test")

        let result = inventory.consume(10, for: "orb_test")

        XCTAssertFalse(result)
        XCTAssertEqual(inventory.count(for: "orb_test"), 5)  // Unchanged
    }

    func testShardInventoryConsumeExact() {
        var inventory = ShardInventory()
        inventory.add(10, for: "orb_test")

        let result = inventory.consume(10, for: "orb_test")

        XCTAssertTrue(result)
        XCTAssertEqual(inventory.count(for: "orb_test"), 0)
    }

    func testShardInventoryMultipleOrbs() {
        var inventory = ShardInventory()

        inventory.add(10, for: "orb_a")
        inventory.add(20, for: "orb_b")

        XCTAssertEqual(inventory.count(for: "orb_a"), 10)
        XCTAssertEqual(inventory.count(for: "orb_b"), 20)
    }

    // MARK: - OrbStarLevels Tests

    func testOrbStarLevelsInitialState() {
        let starLevels = OrbStarLevels()

        XCTAssertEqual(starLevels.level(for: "orb_test"), 0)
    }

    func testOrbStarLevelsUnlock() {
        var starLevels = OrbStarLevels()

        starLevels.unlock("orb_test")

        XCTAssertEqual(starLevels.level(for: "orb_test"), 1)
    }

    func testOrbStarLevelsUpgrade() {
        var starLevels = OrbStarLevels()
        starLevels.unlock("orb_test")

        let newLevel = starLevels.upgrade("orb_test")

        XCTAssertEqual(newLevel, 2)
        XCTAssertEqual(starLevels.level(for: "orb_test"), 2)
    }

    func testOrbStarLevelsUpgradeToMax() {
        var starLevels = OrbStarLevels()
        starLevels.unlock("orb_test")

        // Upgrade to max (5)
        _ = starLevels.upgrade("orb_test")  // 2
        _ = starLevels.upgrade("orb_test")  // 3
        _ = starLevels.upgrade("orb_test")  // 4
        let maxLevel = starLevels.upgrade("orb_test")  // 5

        XCTAssertEqual(maxLevel, 5)
        XCTAssertEqual(starLevels.level(for: "orb_test"), 5)
    }

    func testOrbStarLevelsCannotExceedMax() {
        var starLevels = OrbStarLevels()
        starLevels.unlock("orb_test")

        // Upgrade to max
        _ = starLevels.upgrade("orb_test")
        _ = starLevels.upgrade("orb_test")
        _ = starLevels.upgrade("orb_test")
        _ = starLevels.upgrade("orb_test")  // Now at 5

        // Try to upgrade past max
        let result = starLevels.upgrade("orb_test")

        XCTAssertNil(result)
        XCTAssertEqual(starLevels.level(for: "orb_test"), 5)
    }

    func testOrbStarLevelsCanUpgrade() {
        var starLevels = OrbStarLevels()

        // Not owned - can't upgrade
        XCTAssertFalse(starLevels.canUpgrade("orb_test"))

        // Owned at level 1 - can upgrade
        starLevels.unlock("orb_test")
        XCTAssertTrue(starLevels.canUpgrade("orb_test"))

        // At max level - can't upgrade
        _ = starLevels.upgrade("orb_test")
        _ = starLevels.upgrade("orb_test")
        _ = starLevels.upgrade("orb_test")
        _ = starLevels.upgrade("orb_test")
        XCTAssertFalse(starLevels.canUpgrade("orb_test"))
    }

    func testMaxStarLevel() {
        XCTAssertEqual(OrbStarLevels.maxStarLevel, 5)
    }

    // MARK: - GachaPityCounter Tests

    func testGachaPityCounterInitialState() {
        let pity = GachaPityCounter()

        XCTAssertEqual(pity.pullsSinceRare, 0)
        XCTAssertEqual(pity.pullsSinceEpic, 0)
        XCTAssertEqual(pity.pullsSinceLegendary, 0)
        XCTAssertEqual(pity.totalPulls, 0)
    }

    func testGachaPityCounterRecordCommonPull() {
        var pity = GachaPityCounter()

        pity.recordPull(rarity: .common)

        XCTAssertEqual(pity.totalPulls, 1)
        XCTAssertEqual(pity.pullsSinceRare, 1)
        XCTAssertEqual(pity.pullsSinceEpic, 1)
        XCTAssertEqual(pity.pullsSinceLegendary, 1)
    }

    func testGachaPityCounterRecordUncommonPull() {
        var pity = GachaPityCounter()

        pity.recordPull(rarity: .uncommon)

        XCTAssertEqual(pity.pullsSinceRare, 1)
        XCTAssertEqual(pity.pullsSinceEpic, 1)
        XCTAssertEqual(pity.pullsSinceLegendary, 1)
    }

    func testGachaPityCounterRecordRarePull() {
        var pity = GachaPityCounter()
        pity.pullsSinceRare = 10
        pity.pullsSinceEpic = 10
        pity.pullsSinceLegendary = 10

        pity.recordPull(rarity: .rare)

        XCTAssertEqual(pity.pullsSinceRare, 0)  // Reset
        XCTAssertEqual(pity.pullsSinceEpic, 11)  // Incremented
        XCTAssertEqual(pity.pullsSinceLegendary, 11)  // Incremented
    }

    func testGachaPityCounterRecordEpicPull() {
        var pity = GachaPityCounter()
        pity.pullsSinceRare = 10
        pity.pullsSinceEpic = 10
        pity.pullsSinceLegendary = 10

        pity.recordPull(rarity: .epic)

        XCTAssertEqual(pity.pullsSinceRare, 0)  // Reset
        XCTAssertEqual(pity.pullsSinceEpic, 0)  // Reset
        XCTAssertEqual(pity.pullsSinceLegendary, 11)  // Incremented
    }

    func testGachaPityCounterRecordLegendaryPull() {
        var pity = GachaPityCounter()
        pity.pullsSinceRare = 10
        pity.pullsSinceEpic = 10
        pity.pullsSinceLegendary = 10

        pity.recordPull(rarity: .legendary)

        XCTAssertEqual(pity.pullsSinceRare, 0)  // Reset
        XCTAssertEqual(pity.pullsSinceEpic, 0)  // Reset
        XCTAssertEqual(pity.pullsSinceLegendary, 0)  // Reset
    }

    func testGachaPityCounterGuaranteedRarity() {
        var pity = GachaPityCounter()

        // No guarantee initially
        XCTAssertNil(pity.guaranteedRarity())

        // At rare pity threshold (30 - 1 = 29)
        pity.pullsSinceRare = 29
        XCTAssertEqual(pity.guaranteedRarity(), .rare)

        // Epic overrides rare (50 - 1 = 49)
        pity.pullsSinceEpic = 49
        XCTAssertEqual(pity.guaranteedRarity(), .epic)

        // Legendary overrides all (100 - 1 = 99)
        pity.pullsSinceLegendary = 99
        XCTAssertEqual(pity.guaranteedRarity(), .legendary)
    }

    // MARK: - GachaPullResult Tests

    func testGachaPullResultCreation() {
        let result = GachaPullResult(
            orbId: "orb_test",
            orbName: "Test Orb",
            rarity: .rare,
            shardsAwarded: 10,
            wasGuaranteed: false
        )

        XCTAssertEqual(result.orbId, "orb_test")
        XCTAssertEqual(result.orbName, "Test Orb")
        XCTAssertEqual(result.rarity, .rare)
        XCTAssertEqual(result.shardsAwarded, 10)
        XCTAssertFalse(result.wasGuaranteed)
        XCTAssertNotNil(result.timestamp)
    }

    func testGachaPullResultGuaranteed() {
        let result = GachaPullResult(
            orbId: "orb_test",
            orbName: "Test Orb",
            rarity: .legendary,
            shardsAwarded: 40,
            wasGuaranteed: true
        )

        XCTAssertTrue(result.wasGuaranteed)
    }

    // MARK: - GachaPullHistory Tests

    func testGachaPullHistoryInitialState() {
        let history = GachaPullHistory()

        XCTAssertTrue(history.pulls.isEmpty)
        XCTAssertTrue(history.recent.isEmpty)
    }

    func testGachaPullHistoryAddPull() {
        var history = GachaPullHistory()
        let pull = GachaPullResult(
            orbId: "orb_test",
            orbName: "Test",
            rarity: .common,
            shardsAwarded: 3
        )

        history.add(pull)

        XCTAssertEqual(history.pulls.count, 1)
        XCTAssertEqual(history.pulls[0].orbId, "orb_test")
    }

    func testGachaPullHistoryMostRecentFirst() {
        var history = GachaPullHistory()

        let pull1 = GachaPullResult(orbId: "orb_1", orbName: "First", rarity: .common, shardsAwarded: 3)
        let pull2 = GachaPullResult(orbId: "orb_2", orbName: "Second", rarity: .rare, shardsAwarded: 10)

        history.add(pull1)
        history.add(pull2)

        XCTAssertEqual(history.pulls[0].orbId, "orb_2")  // Most recent first
        XCTAssertEqual(history.pulls[1].orbId, "orb_1")
    }

    func testGachaPullHistoryRecentLimit() {
        var history = GachaPullHistory()

        // Add 15 pulls
        for i in 0..<15 {
            let pull = GachaPullResult(
                orbId: "orb_\(i)",
                orbName: "Orb \(i)",
                rarity: .common,
                shardsAwarded: 3
            )
            history.add(pull)
        }

        // Recent should only show last 10
        XCTAssertEqual(history.recent.count, 10)
    }

    // MARK: - OrbRarity Extension Tests

    func testOrbRarityShardsToUnlock() {
        XCTAssertEqual(OrbRarity.common.shardsToUnlock, 10)
        XCTAssertEqual(OrbRarity.uncommon.shardsToUnlock, 25)
        XCTAssertEqual(OrbRarity.rare.shardsToUnlock, 50)
        XCTAssertEqual(OrbRarity.epic.shardsToUnlock, 100)
        XCTAssertEqual(OrbRarity.legendary.shardsToUnlock, 200)
    }

    func testOrbRarityShardsPerStar() {
        XCTAssertEqual(OrbRarity.common.shardsPerStar, 10)
        XCTAssertEqual(OrbRarity.uncommon.shardsPerStar, 25)
        XCTAssertEqual(OrbRarity.rare.shardsPerStar, 50)
        XCTAssertEqual(OrbRarity.epic.shardsPerStar, 100)
        XCTAssertEqual(OrbRarity.legendary.shardsPerStar, 200)
    }

    func testOrbRarityDropRate() {
        XCTAssertEqual(OrbRarity.common.dropRate, 50.0)
        XCTAssertEqual(OrbRarity.uncommon.dropRate, 25.0)
        XCTAssertEqual(OrbRarity.rare.dropRate, 15.0)
        XCTAssertEqual(OrbRarity.epic.dropRate, 7.0)
        XCTAssertEqual(OrbRarity.legendary.dropRate, 3.0)
    }

    func testOrbRarityShardsPerPull() {
        XCTAssertEqual(OrbRarity.common.shardsPerPull, 3)
        XCTAssertEqual(OrbRarity.uncommon.shardsPerPull, 5)
        XCTAssertEqual(OrbRarity.rare.shardsPerPull, 10)
        XCTAssertEqual(OrbRarity.epic.shardsPerPull, 20)
        XCTAssertEqual(OrbRarity.legendary.shardsPerPull, 40)
    }
}
