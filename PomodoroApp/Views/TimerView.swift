import SwiftUI

struct TimerView: View {
    @EnvironmentObject var session: PomodoroSession
    @EnvironmentObject var rewardsManager: RewardsManager
    @State private var showSettings = false
    @State private var showCelebration = false
    @State private var showOrbSelector = false
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

            // Main timer display centered in the screen
            timerDisplay
                .offset(y: -40)

            VStack(spacing: 0) {
                // Top navigation bar
                topNavBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

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
        .sheet(isPresented: $showOrbSelector) {
            QuickOrbSelectorView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
            // Stardust balance (left side)
            if session.state == .idle {
                StardustBadge(amount: rewardsManager.balance.current, size: .small)
            }

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
                .accessibilityLabel("Settings")
                .accessibilityHint("Opens app settings")
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

            // Gradient orb in center (uses equipped style with star level)
            GradientOrbView(
                state: orbState,
                size: 144,
                style: rewardsManager.equippedStyle,
                starLevel: equippedStarLevel
            )
            .contentShape(Circle())
            .onTapGesture {
                if session.state == .idle {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showOrbSelector = true
                }
            }
            .accessibilityLabel("\(rewardsManager.equippedStyle.name) orb, \(equippedStarLevel) star")
            .accessibilityHint(session.state == .idle ? "Tap to change orb" : "")
            .accessibilityAddTraits(session.state == .idle ? .isButton : [])
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

    private var equippedStarLevel: Int {
        rewardsManager.starLevel(for: rewardsManager.collection.equippedOrbStyleId)
    }

    // MARK: - State Section
    private var stateSection: some View {
        VStack(spacing: 8) {
            // Timer text
            AnimatedTimerText(
                timeRemaining: displayTimeRemaining,
                isRunning: session.timer.isRunning
            )
            .padding(.top, 16)

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

            // Motivational message during session
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

    private var displayTimeRemaining: Int {
        if session.state == .idle {
            return session.focusDuration * 60
        }
        // For focusing and cooling down, show the timer
        return session.timer.timeRemaining
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
                RoundedButton("Begin", style: .primary, customPrimaryColor: rewardsManager.equippedStyle.primaryColor) {
                    session.startFocusSession()
                }

            case .focusing:
                VStack(spacing: 16) {
                    // Only show Give Up button after grace period ends
                    if !session.isInGracePeriod {
                        RoundedButton("Give Up", style: .secondary) {
                            session.requestQuit()
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // Grace period cancel button with countdown (first 10 seconds, no penalty)
                    if session.isInGracePeriod {
                        GracePeriodCancelButton(session: session)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: session.isInGracePeriod)

            case .coolingDown:
                // Buttons shown in overlay instead
                EmptyView()
            }
        }
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

// MARK: - Grace Period Cancel Button

/// Cancel button shown during grace period with countdown
private struct GracePeriodCancelButton: View {
    @ObservedObject var session: PomodoroSession
    @State private var remainingSeconds: Int = 10
    @State private var opacity: Double = 1.0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Button {
            session.cancelInGracePeriod()
        } label: {
            Text("Cancel (\(remainingSeconds)s)")
                .font(.pomCaption)
                .foregroundColor(.pomTextTertiary)
        }
        .accessibilityLabel("Cancel session")
        .accessibilityHint("Cancel within \(remainingSeconds) seconds without penalty")
        .opacity(opacity)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .onReceive(timer) { _ in
            updateCountdown()
        }
        .onAppear {
            updateCountdown()
        }
    }

    private func updateCountdown() {
        guard let startTime = session.sessionStartTime else {
            remainingSeconds = 0
            return
        }

        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = Int(PomodoroSession.gracePeriodSeconds - elapsed)

        if remaining > 0 {
            remainingSeconds = remaining
        } else {
            remainingSeconds = 0
            // Fade out when countdown ends
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0
            }
        }
    }
}

#Preview {
    TimerView()
        .environmentObject(PomodoroSession())
        .environmentObject(RewardsManager.shared)
}
