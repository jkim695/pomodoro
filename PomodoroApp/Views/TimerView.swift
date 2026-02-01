import SwiftUI

struct TimerView: View {
    @EnvironmentObject var session: PomodoroSession
    @EnvironmentObject var rewardsManager: RewardsManager
    @State private var showSettings = false
    @State private var showCelebration = false
    @State private var previousState: SessionState = .idle
    @State private var earnedStardust: Int = 0
    @State private var earnedMilestones: [Milestone] = []
    @AppStorage("completedSessions") private var completedSessions: Int = 0

    var body: some View {
        ZStack {
            // Background
            Color.pomBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top navigation bar
                topNavBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Spacer()

                // Main timer display
                timerDisplay

                Spacer()

                // State label and session counter
                stateSection
                    .padding(.bottom, 32)

                // Action button
                actionButton
                    .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 40)
            }

            // Celebration overlay with rewards
            if showCelebration {
                RewardCelebrationView(
                    earnedStardust: earnedStardust,
                    milestones: earnedMilestones
                ) {
                    showCelebration = false
                    rewardsManager.clearPendingMilestones()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: session.state) { newState in
            // Trigger celebration when focus session completes
            if previousState == .focusing && newState == .idle {
                completedSessions += 1
                // Capture reward info for celebration display
                earnedStardust = rewardsManager.balance.lastSessionReward
                earnedMilestones = rewardsManager.pendingMilestones
                triggerCelebration()
            }
            previousState = newState
        }
        .onAppear {
            previousState = session.state
            // Migrate existing sessions if this is first launch with rewards
            rewardsManager.migrateExistingSessions(completedSessions)
        }
    }

    // MARK: - Top Navigation Bar
    private var topNavBar: some View {
        HStack {
            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.pomTextSecondary)
                    .padding(8)
            }
        }
    }

    // MARK: - Timer Display with Orb
    private var timerDisplay: some View {
        ZStack {
            // When idle: show duration slider (includes its own track)
            // When focusing: show progress ring
            if session.state == .idle {
                CircularDurationSlider(
                    duration: $session.focusDuration,
                    size: 252,
                    trackWidth: 12,
                    isEnabled: true
                )
            } else {
                // Progress ring (only during focus sessions)
                CircularProgressView(
                    progress: session.timer.progress,
                    lineWidth: 12,
                    size: 252
                )
            }

            // Gradient orb in center (uses equipped style)
            GradientOrbView(
                state: orbState,
                size: 144,
                style: rewardsManager.equippedStyle
            )
        }
    }

    private var orbState: GradientOrbView.OrbState {
        switch session.state {
        case .idle:
            return .idle
        case .focusing:
            return .focusing
        }
    }

    // MARK: - State Section
    private var stateSection: some View {
        VStack(spacing: 8) {
            // Timer text
            AnimatedTimerText(
                timeRemaining: displayTimeRemaining,
                isRunning: session.timer.isRunning
            )

            // State label
            Text(stateLabel)
                .font(.pomHeading2)
                .fontWeight(.semibold)
                .foregroundColor(.pomTextSecondary)
                .textCase(.uppercase)
                .tracking(2)

            // Session counter or app blocked info
            if session.state == .idle {
                Text("Today: \(completedSessions) session\(completedSessions == 1 ? "" : "s")")
                    .font(.pomCaption)
                    .foregroundColor(.pomTextTertiary)
            } else if session.state == .focusing && hasBlockedApps {
                Text("\(blockedAppCount) app\(blockedAppCount == 1 ? "" : "s") blocked")
                    .font(.pomCaption)
                    .foregroundColor(.pomTextTertiary)
            }
        }
    }

    private var stateLabel: String {
        switch session.state {
        case .idle:
            return "Focus"
        case .focusing:
            return "Focusing"
        }
    }

    private var displayTimeRemaining: Int {
        if session.state == .idle {
            return session.focusDuration * 60
        }
        return session.timer.timeRemaining
    }

    private var hasBlockedApps: Bool {
        !session.selection.applicationTokens.isEmpty || !session.selection.categoryTokens.isEmpty
    }

    private var blockedAppCount: Int {
        session.selection.applicationTokens.count + session.selection.categoryTokens.count
    }

    // MARK: - Action Button
    private var actionButton: some View {
        Group {
            switch session.state {
            case .idle:
                RoundedButton("Begin", style: .primary) {
                    session.startFocusSession()
                }

            case .focusing:
                RoundedButton("End Session", style: .secondary) {
                    session.endFocusSession()
                }
            }
        }
    }

    // MARK: - Celebration
    private func triggerCelebration() {
        showCelebration = true
    }
}

#Preview {
    TimerView()
        .environmentObject(PomodoroSession())
        .environmentObject(RewardsManager.shared)
}
