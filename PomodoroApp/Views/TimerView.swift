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
    @AppStorage("focusedMinutesToday") private var focusedMinutesToday: Int = 0
    @AppStorage("lastFocusDate") private var lastFocusDate: String = ""

    /// The duration of the session that was started (captured at start to track on completion)
    @State private var sessionDurationAtStart: Int = 0

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

            // Cool-down overlay (quit confirmation)
            if session.state == .coolingDown {
                CoolDownOverlayView(
                    anteAmount: RewardsManager.sessionAnteAmount,
                    onResume: { session.cancelQuit() },
                    onConfirmQuit: { session.confirmQuit() }
                )
            }

            // Insufficient funds overlay
            if session.startError == .insufficientStardust {
                InsufficientFundsOverlayView(
                    required: RewardsManager.sessionAnteAmount,
                    current: rewardsManager.balance.current,
                    onDismiss: { session.startError = nil }
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: session.state) { newState in
            // Capture session duration when starting
            if previousState == .idle && newState == .focusing {
                sessionDurationAtStart = session.focusDuration
            }

            // Trigger celebration when focus session completes (from focusing or coolingDown)
            // Only celebrate if there was a reward (natural completion, not quit)
            let wasInSession = previousState == .focusing || previousState == .coolingDown
            if wasInSession && newState == .idle && rewardsManager.balance.lastSessionReward > 0 {
                completedSessions += 1
                focusedMinutesToday += sessionDurationAtStart
                // Capture reward info for celebration display
                earnedStardust = rewardsManager.balance.lastSessionReward
                earnedMilestones = rewardsManager.pendingMilestones
                triggerCelebration()
            }
            previousState = newState
        }
        .onAppear {
            previousState = session.state
            // Reset daily counter if it's a new day
            resetDailyCounterIfNeeded()
            // Migrate existing sessions if this is first launch with rewards
            rewardsManager.migrateExistingSessions(completedSessions)
        }
    }

    // MARK: - Top Navigation Bar
    private var topNavBar: some View {
        HStack {
            Spacer()

            if session.state == .idle {
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
    }

    // MARK: - Timer Display with Orb
    private var timerDisplay: some View {
        ZStack {
            // When idle: show duration slider (includes its own track)
            // When focusing or cooling down: show progress ring
            if session.state == .idle {
                CircularDurationSlider(
                    duration: $session.focusDuration,
                    size: 252,
                    trackWidth: 12,
                    isEnabled: true,
                    accentColor: rewardsManager.equippedStyle.primaryColor
                )
            } else {
                // Progress ring (during focus sessions and cool-down)
                // Animate from slider's fill position for smooth transition
                CircularProgressView(
                    progress: session.timer.progress,
                    lineWidth: 12,
                    size: 252,
                    animateFromProgress: sliderFillProgress,
                    accentColor: rewardsManager.equippedStyle.primaryColor
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
        case .focusing, .coolingDown:
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

            // Focus time today or app blocked info
            if session.state == .idle {
                Text("Today: \(focusedMinutesToday) min\(focusedMinutesToday == 1 ? "" : "s") focused")
                    .font(.pomCaption)
                    .foregroundColor(.pomTextTertiary)
            } else if (session.state == .focusing || session.state == .coolingDown) && hasBlockedApps {
                Text("\(blockedAppCount) app\(blockedAppCount == 1 ? "" : "s") blocked")
                    .font(.pomCaption)
                    .foregroundColor(.pomTextTertiary)
            }

            // Focus message during session
            if session.state == .focusing {
                Text("Put down your phone and focus on your work.")
                    .font(.pomCaption)
                    .foregroundColor(.pomTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }
        }
    }

    private var stateLabel: String {
        switch session.state {
        case .idle:
            return "Focus"
        case .focusing:
            return "Focusing"
        case .coolingDown:
            return "Paused"
        }
    }

    private var displayTimeRemaining: Int {
        if session.state == .idle {
            return session.focusDuration * 60
        }
        // For focusing and cooling down, show the timer
        return session.timer.timeRemaining
    }

    private var stardustGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var hasBlockedApps: Bool {
        !session.selection.applicationTokens.isEmpty || !session.selection.categoryTokens.isEmpty
    }

    private var blockedAppCount: Int {
        session.selection.applicationTokens.count + session.selection.categoryTokens.count
    }

    // Progress of the duration slider (0 to 1) for smooth animation transition
    private var sliderFillProgress: Double {
        let minDuration = 10
        let maxDuration = 180
        return Double(session.focusDuration - minDuration) / Double(maxDuration - minDuration)
    }

    // MARK: - Action Button
    private var actionButton: some View {
        Group {
            switch session.state {
            case .idle:
                VStack(spacing: 12) {
                    RoundedButton("Begin", style: .primary, customPrimaryColor: rewardsManager.equippedStyle.primaryColor) {
                        session.startFocusSession()
                    }

                    // Ante toggle for bonus rewards
                    anteToggle
                }

            case .focusing:
                RoundedButton("Give Up", style: .secondary) {
                    session.requestQuit()
                }

            case .coolingDown:
                // Buttons shown in overlay instead
                EmptyView()
            }
        }
    }

    // MARK: - Ante Toggle
    private var anteToggle: some View {
        Button {
            if rewardsManager.canAffordAnte {
                session.useAnte.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: session.useAnte ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(session.useAnte ? .pomAccent : .pomTextTertiary)

                Text("Bet \(RewardsManager.sessionAnteAmount)")
                    .font(.pomCaption)
                    .foregroundColor(rewardsManager.canAffordAnte ? .pomTextSecondary : .pomTextTertiary)

                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(stardustGradient)

                Text("for 2× rewards")
                    .font(.pomCaption)
                    .foregroundColor(rewardsManager.canAffordAnte ? .pomTextSecondary : .pomTextTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(session.useAnte ? Color.pomAccent.opacity(0.15) : Color.clear)
            )
        }
        .disabled(!rewardsManager.canAffordAnte)
        .opacity(rewardsManager.canAffordAnte ? 1.0 : 0.5)
    }

    // MARK: - Celebration
    private func triggerCelebration() {
        showCelebration = true
    }

    // MARK: - Daily Reset
    private func resetDailyCounterIfNeeded() {
        let today = todayDateString()
        if lastFocusDate != today {
            focusedMinutesToday = 0
            lastFocusDate = today
        }
    }

    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

#Preview {
    TimerView()
        .environmentObject(PomodoroSession())
        .environmentObject(RewardsManager.shared)
}
