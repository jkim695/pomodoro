import Foundation
import SwiftUI
import Combine

/// Notification posted when a focus session is successfully completed
extension Notification.Name {
    static let sessionCompleted = Notification.Name("sessionCompleted")
}

/// Errors that can occur during purchase
enum PurchaseError: Error, LocalizedError {
    case insufficientBalance
    case alreadyOwned
    case styleNotFound

    var errorDescription: String? {
        switch self {
        case .insufficientBalance:
            return "Not enough Stardust"
        case .alreadyOwned:
            return "Already owned"
        case .styleNotFound:
            return "Style not found"
        }
    }
}

/// Central manager for the rewards/gamification system
@MainActor
final class RewardsManager: ObservableObject {
    static let shared = RewardsManager()

    /// Stardust required to start a focus session (ante/buy-in)
    static let sessionAnteAmount: Int = 50

    // MARK: - Published State

    @Published var balance: StardustBalance
    @Published var progress: UserProgress
    @Published var collection: UserCollection

    /// Newly achieved milestones from the last session (for celebration display)
    @Published var pendingMilestones: [Milestone] = []

    // MARK: - Persistence Keys

    private static let balanceKey = "rewards.balance"
    private static let progressKey = "rewards.progress"
    private static let collectionKey = "rewards.collection"

    // MARK: - Computed Properties

    /// The currently equipped orb style
    var equippedStyle: OrbStyle {
        OrbCatalog.style(for: collection.equippedOrbStyleId) ?? OrbCatalog.defaultStyle
    }

    /// All styles the user doesn't own yet
    var lockedStyles: [OrbStyle] {
        OrbCatalog.all.filter { !collection.owns($0.id) }
    }

    /// Styles that can be purchased (not owned, user has enough balance)
    var purchasableStyles: [OrbStyle] {
        lockedStyles.filter { balance.current >= $0.price }
    }

    /// All owned styles
    var ownedStyles: [OrbStyle] {
        OrbCatalog.all.filter { collection.owns($0.id) }
    }

    /// Whether user has enough Stardust to start a session (can afford ante)
    var canStartSession: Bool {
        balance.canAffordAnte(Self.sessionAnteAmount)
    }

    /// Whether there's currently an ante held in escrow
    var hasAnteInEscrow: Bool {
        balance.anteInEscrow > 0
    }

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // Load persisted data
        self.balance = Self.loadBalance()
        self.progress = Self.loadProgress()
        self.collection = Self.loadCollection()

        // Recover any orphaned ante from a previous crash
        recoverOrphanedAnte()

        // Listen for session completion notifications
        NotificationCenter.default.publisher(for: .sessionCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let duration = notification.userInfo?["duration"] as? Int {
                    self?.awardSessionCompletion(duration: duration)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Reward Calculation

    /// Calculate Stardust reward for a session
    /// - Parameters:
    ///   - minutes: Session duration in minutes
    ///   - completed: Whether session was completed successfully
    /// - Returns: Stardust amount to award
    func calculateReward(forDuration minutes: Int, completed: Bool) -> Int {
        guard completed else { return 0 }

        // Base rate: ~0.4 Stardust per minute
        // 25 min = 10, 50 min = 20, 60 min = 24
        let baseReward = Int(Double(minutes) * 0.4)

        // Apply streak bonus
        let streakMultiplier = 1.0 + progress.streakBonusMultiplier
        let withStreak = Int(Double(baseReward) * streakMultiplier)

        return max(withStreak, 1) // Minimum 1 Stardust
    }

    /// Award Stardust for a completed session
    /// - Parameter duration: Session duration in minutes
    func awardSessionCompletion(duration: Int) {
        let reward = calculateReward(forDuration: duration, completed: true)

        // Update balance
        balance.add(reward)

        // Update progress
        progress.recordSession(durationMinutes: duration)

        // Check for new milestones
        let newMilestones = checkAndAwardMilestones()
        pendingMilestones = newMilestones

        // Persist
        save()
    }

    /// Check for newly achieved milestones and award bonus Stardust
    /// - Returns: List of newly achieved milestones
    func checkAndAwardMilestones() -> [Milestone] {
        var newlyAchieved: [Milestone] = []

        for milestone in Milestones.all {
            // Skip already achieved
            guard !progress.achievedMilestones.contains(milestone.id) else { continue }

            // Check if now achieved
            if milestone.isAchieved(by: progress) {
                progress.achievedMilestones.insert(milestone.id)
                balance.add(milestone.reward)
                newlyAchieved.append(milestone)
            }
        }

        if !newlyAchieved.isEmpty {
            save()
        }

        return newlyAchieved
    }

    /// Clear pending milestones (after celebration is shown)
    func clearPendingMilestones() {
        pendingMilestones = []
    }

    // MARK: - Shop Operations

    /// Check if user can purchase a style
    func canPurchase(_ style: OrbStyle) -> Bool {
        !collection.owns(style.id) && balance.current >= style.price
    }

    /// Purchase an orb style
    /// - Parameter style: The style to purchase
    /// - Returns: Success or error
    func purchase(_ style: OrbStyle) -> Result<Void, PurchaseError> {
        // Validate
        guard !collection.owns(style.id) else {
            return .failure(.alreadyOwned)
        }
        guard balance.current >= style.price else {
            return .failure(.insufficientBalance)
        }

        // Deduct balance
        guard balance.spend(style.price) else {
            return .failure(.insufficientBalance)
        }

        // Add to collection
        collection.addPurchase(styleId: style.id, price: style.price)

        // Persist
        save()

        return .success(())
    }

    /// Equip an owned orb style
    /// - Parameter style: The style to equip
    /// - Returns: true if successful
    @discardableResult
    func equip(_ style: OrbStyle) -> Bool {
        guard collection.equip(style.id) else { return false }
        save()
        return true
    }

    // MARK: - Session Ante Management

    /// Hold ante for session start (deducts from balance, holds in escrow)
    /// - Returns: true if ante was successfully held, false if insufficient balance
    func holdSessionAnte() -> Bool {
        guard balance.holdAnte(Self.sessionAnteAmount) else { return false }
        // Also persist to SharedDataManager for crash recovery
        SharedDataManager.shared.anteInEscrow = Self.sessionAnteAmount
        save()
        return true
    }

    /// Return ante after successful session completion (adds back to balance)
    func returnSessionAnte() {
        balance.returnAnte()
        SharedDataManager.shared.anteInEscrow = 0
        save()
    }

    /// Burn ante when user quits early (ante is permanently lost)
    func burnSessionAnte() {
        balance.burnAnte()
        SharedDataManager.shared.anteInEscrow = 0
        save()
    }

    /// Recover orphaned ante from a previous crash
    /// If the app crashed during a session, return the ante to the user
    private func recoverOrphanedAnte() {
        let orphanedAnte = SharedDataManager.shared.anteInEscrow
        let sessionActive = SharedDataManager.shared.isSessionActive

        // If there's ante in escrow but no active session, the app crashed
        // Return the ante to the user (benefit of the doubt)
        if orphanedAnte > 0 && !sessionActive {
            balance.current += orphanedAnte
            balance.anteInEscrow = 0
            SharedDataManager.shared.anteInEscrow = 0
            save()
            print("Recovered \(orphanedAnte) orphaned Stardust ante from previous crash")
        }
    }

    // MARK: - Persistence

    private func save() {
        Self.saveBalance(balance)
        Self.saveProgress(progress)
        Self.saveCollection(collection)
    }

    /// Force refresh from storage (useful after app becomes active)
    func refresh() {
        balance = Self.loadBalance()
        progress = Self.loadProgress()
        collection = Self.loadCollection()
    }

    // MARK: - Static Persistence Helpers

    private static func saveBalance(_ balance: StardustBalance) {
        do {
            let data = try PropertyListEncoder().encode(balance)
            UserDefaults.standard.set(data, forKey: balanceKey)
        } catch {
            print("Failed to save rewards balance: \(error)")
        }
    }

    private static func loadBalance() -> StardustBalance {
        guard let data = UserDefaults.standard.data(forKey: balanceKey) else {
            return StardustBalance()
        }
        do {
            return try PropertyListDecoder().decode(StardustBalance.self, from: data)
        } catch {
            print("Failed to load rewards balance: \(error)")
            return StardustBalance()
        }
    }

    private static func saveProgress(_ progress: UserProgress) {
        do {
            let data = try PropertyListEncoder().encode(progress)
            UserDefaults.standard.set(data, forKey: progressKey)
        } catch {
            print("Failed to save rewards progress: \(error)")
        }
    }

    private static func loadProgress() -> UserProgress {
        guard let data = UserDefaults.standard.data(forKey: progressKey) else {
            return UserProgress()
        }
        do {
            return try PropertyListDecoder().decode(UserProgress.self, from: data)
        } catch {
            print("Failed to load rewards progress: \(error)")
            return UserProgress()
        }
    }

    private static func saveCollection(_ collection: UserCollection) {
        do {
            let data = try PropertyListEncoder().encode(collection)
            UserDefaults.standard.set(data, forKey: collectionKey)
        } catch {
            print("Failed to save rewards collection: \(error)")
        }
    }

    private static func loadCollection() -> UserCollection {
        guard let data = UserDefaults.standard.data(forKey: collectionKey) else {
            return UserCollection()
        }
        do {
            return try PropertyListDecoder().decode(UserCollection.self, from: data)
        } catch {
            print("Failed to load rewards collection: \(error)")
            return UserCollection()
        }
    }

    // MARK: - Migration

    /// Migrate existing session count to rewards (for existing users)
    /// - Parameter existingSessions: Number of sessions from @AppStorage
    func migrateExistingSessions(_ existingSessions: Int) {
        guard existingSessions > 0 && progress.totalSessionsCompleted == 0 else { return }

        // Award retroactive Stardust (10 per session)
        let retroactiveReward = existingSessions * 10
        balance.add(retroactiveReward)

        // Update progress (assume 25-min sessions)
        for _ in 0..<existingSessions {
            progress.recordSession(durationMinutes: 25)
        }

        // Check milestones
        _ = checkAndAwardMilestones()

        save()
    }
}
