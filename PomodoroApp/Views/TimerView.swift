import SwiftUI

struct TimerView: View {
    @EnvironmentObject var session: PomodoroSession
    @State private var showSettings = false
    @State private var showCelebration = false
    @State private var previousState: SessionState = .idle
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

                // Quick duration picker (only show when idle)
                if session.state == .idle {
                    quickDurationPicker
                        .padding(.top, 24)
                        .padding(.horizontal, 24)
                }

                Spacer()
                    .frame(height: 40)
            }

            // Celebration overlay
            if showCelebration {
                celebrationOverlay
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: session.state) { newState in
            // Trigger celebration when focus session completes
            if previousState == .focusing && newState == .onBreak {
                completedSessions += 1
                triggerCelebration()
            }
            previousState = newState
        }
        .onAppear {
            previousState = session.state
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
            // Progress ring
            CircularProgressView(
                progress: session.timer.progress,
                lineWidth: 20,
                size: 280,
                isFocusing: session.state != .onBreak
            )

            // Gradient orb in center
            GradientOrbView(
                state: orbState,
                size: 160
            )
        }
    }

    private var orbState: GradientOrbView.OrbState {
        switch session.state {
        case .idle:
            return .idle
        case .focusing:
            return .focusing
        case .onBreak:
            return .onBreak
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
        case .onBreak:
            return "Break"
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
                    session.endFocusSession(startBreak: false)
                }

            case .onBreak:
                RoundedButton("Skip Break", style: .secondary) {
                    session.endBreak()
                }
            }
        }
    }

    // MARK: - Quick Duration Picker
    private var quickDurationPicker: some View {
        let durations = [25, 50, 60]
        return HStack(spacing: 12) {
            ForEach(durations, id: \.self) { duration in
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    session.focusDuration = duration
                } label: {
                    Text("\(duration)m")
                        .font(.pomBody)
                        .fontWeight(.medium)
                        .foregroundColor(session.focusDuration == duration ? .white : .pomTextSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(session.focusDuration == duration ? Color.pomPrimary : Color.pomCardBackgroundAlt)
                        )
                }
            }
        }
    }

    // MARK: - Celebration Overlay
    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.pomSecondary)

                Text("Great job!")
                    .font(.pomHeading1)
                    .foregroundColor(.white)

                Text("Focus session complete")
                    .font(.pomBody)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(48)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.pomTextPrimary)
            )
            .scaleEffect(showCelebration ? 1 : 0.5)
            .opacity(showCelebration ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showCelebration)
        }
        .onTapGesture {
            withAnimation {
                showCelebration = false
            }
        }
    }

    private func triggerCelebration() {
        withAnimation {
            showCelebration = true
        }

        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCelebration = false
            }
        }
    }
}

#Preview {
    TimerView()
        .environmentObject(PomodoroSession())
}
