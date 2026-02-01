import SwiftUI

struct TimerView: View {
    @EnvironmentObject var session: PomodoroSession
    @State private var showAppSelection = false
    @State private var showSettings = false
    @State private var showCelebration = false
    @State private var previousState: SessionState = .idle

    var body: some View {
        ZStack {
            // Background
            Color.pomCream
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Timer display with circular progress
                timerDisplay

                // Status text
                statusText

                Spacer()

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
        .sheet(isPresented: $showAppSelection) {
            AppSelectionView()
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

    // MARK: - Timer Display
    private var timerDisplay: some View {
        ZStack {
            CircularProgressView(progress: session.timer.progress)

            VStack(spacing: 8) {
                AnimatedTimerText(
                    timeRemaining: session.timer.timeRemaining,
                    isRunning: session.timer.isRunning
                )

                if session.state != .idle {
                    Text(session.state == .focusing ? "Focus Time" : "Break Time")
                        .font(.pomCaption)
                        .foregroundColor(.pomLightBrown)
                }
            }
        }
    }

    // MARK: - Status Text
    private var statusText: some View {
        Group {
            switch session.state {
            case .idle:
                VStack(spacing: 8) {
                    Text("Ready to focus?")
                        .font(.pomHeading)
                        .foregroundColor(.pomBrown)

                    Text("\(session.focusDuration) minute session")
                        .font(.pomBody)
                        .foregroundColor(.pomLightBrown)
                }
            case .focusing:
                VStack(spacing: 8) {
                    Text("Stay focused!")
                        .font(.pomHeading)
                        .foregroundColor(.pomBrown)

                    if !session.selection.applicationTokens.isEmpty || !session.selection.categoryTokens.isEmpty {
                        let appCount = session.selection.applicationTokens.count + session.selection.categoryTokens.count
                        Text("\(appCount) app\(appCount == 1 ? "" : "s") blocked")
                            .font(.pomCaption)
                            .foregroundColor(.pomLightBrown)
                    }
                }
            case .onBreak:
                VStack(spacing: 8) {
                    Text("Take a break!")
                        .font(.pomHeading)
                        .foregroundColor(.pomBrown)

                    Text("You earned it")
                        .font(.pomBody)
                        .foregroundColor(.pomLightBrown)
                }
            }
        }
        .animation(.stateTransition, value: session.state)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            switch session.state {
            case .idle:
                RoundedButton("Start Focus", style: .primary) {
                    session.startFocusSession()
                }

                IconRoundedButton("Select Apps to Block", icon: "apps.iphone", style: .secondary) {
                    showAppSelection = true
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
