import SwiftUI

struct TimerView: View {
    @EnvironmentObject var session: PomodoroSession
    @State private var showSettings = false
    @State private var showCelebration = false
    @State private var previousState: SessionState = .idle

    var body: some View {
        ZStack {
            // Background
            Color.pomCream
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // HERO: Avatar INSIDE the timer circle
                timerWithAvatar

                Spacer()

                // Status text above buttons
                statusText
                    .padding(.bottom, 24)

                // Action buttons
                actionButtons

                // Bottom toolbar
                bottomToolbar
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

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
                triggerCelebration()
            }
            previousState = newState
        }
        .onAppear {
            previousState = session.state
        }
    }

    // MARK: - Timer with Avatar Inside
    private var timerWithAvatar: some View {
        VStack(spacing: 16) {
            // Timer circle with avatar centered inside
            ZStack {
                CircularProgressView(progress: session.timer.progress)

                // Avatar centered inside the circle
                avatarCompanion
            }

            // Timer text below the circle
            VStack(spacing: 4) {
                AnimatedTimerText(
                    timeRemaining: displayTimeRemaining,
                    isRunning: session.timer.isRunning
                )

                if session.state != .idle {
                    Text(session.state == .focusing ? "Focus Time" : "Break Time")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.pomLightBrown)
                }
            }
        }
    }

    /// Returns the time to display - shows selected duration when idle, actual remaining time otherwise
    private var displayTimeRemaining: Int {
        if session.state == .idle {
            return session.focusDuration * 60  // Convert minutes to seconds
        }
        return session.timer.timeRemaining
    }

    // MARK: - Status Text (Chunky Labels)
    private var statusText: some View {
        Group {
            switch session.state {
            case .idle:
                VStack(spacing: 6) {
                    Text("Ready to focus?")
                        .font(.pomHeading)  // 24pt bold rounded
                        .foregroundColor(.pomBrown)

                    Text("\(session.focusDuration) minute session")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.pomLightBrown)
                }
            case .focusing:
                VStack(spacing: 6) {
                    Text("Stay focused!")
                        .font(.pomHeading)
                        .foregroundColor(.pomBrown)

                    if !session.selection.applicationTokens.isEmpty || !session.selection.categoryTokens.isEmpty {
                        let appCount = session.selection.applicationTokens.count + session.selection.categoryTokens.count
                        Text("\(appCount) app\(appCount == 1 ? "" : "s") blocked")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.pomLightBrown)
                    }
                }
            case .onBreak:
                VStack(spacing: 6) {
                    Text("Take a break!")
                        .font(.pomHeading)
                        .foregroundColor(.pomBrown)

                    Text("You earned it")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.pomLightBrown)
                }
            }
        }
        .animation(.stateTransition, value: session.state)
    }

    // MARK: - Avatar Companion (Centered inside timer circle)
    private var avatarCompanion: some View {
        AvatarWithMessage(
            avatarState: session.avatarState,
            avatarSize: 210,  // Sized to fill the 280px timer circle
            showGroundingShadow: false  // No shadow inside the circular progress ring
        )
        .animation(.stateTransition, value: session.avatarState)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            switch session.state {
            case .idle:
                RoundedButton("Start Focus", style: .primary) {
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
        .animation(.stateTransition, value: session.state)
    }

    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack {
            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.pomLightBrown)
                    .padding(12)
            }
        }
    }

    // MARK: - Celebration Overlay
    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.pomSage)
                    .celebrationAnimation(isActive: showCelebration)

                Text("Great job!")
                    .font(.pomHeading)
                    .foregroundColor(.white)

                Text("Focus session complete")
                    .font(.pomBody)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.pomBrown)
            )
            .scaleEffect(showCelebration ? 1 : 0.5)
            .opacity(showCelebration ? 1 : 0)
            .animation(.celebration, value: showCelebration)
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
