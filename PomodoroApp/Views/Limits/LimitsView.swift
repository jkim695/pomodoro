import SwiftUI
import FamilyControls

/// Main view for the Limits tab - shows time schedules and usage limits
struct LimitsView: View {
    @EnvironmentObject var limitsSession: LimitsSession
    @State private var showAddSchedule = false
    @State private var showAddLimit = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pomBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Time Schedules Section
                        limitsSection(
                            title: "Time Schedules",
                            subtitle: "Block apps during specific hours",
                            icon: "clock.fill",
                            isEmpty: limitsSession.schedules.isEmpty,
                            emptyMessage: "No schedules yet",
                            addAction: { showAddSchedule = true }
                        ) {
                            TimeScheduleListView()
                        }

                        // Usage Limits Section
                        limitsSection(
                            title: "Daily Limits",
                            subtitle: "Limit how long you use certain apps",
                            icon: "chart.bar.fill",
                            isEmpty: limitsSession.limits.isEmpty,
                            emptyMessage: "No limits yet",
                            addAction: { showAddLimit = true }
                        ) {
                            UsageLimitListView()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Limits")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showAddSchedule) {
            TimeScheduleEditorView(schedule: nil)
        }
        .sheet(isPresented: $showAddLimit) {
            UsageLimitEditorView(limit: nil)
        }
        .alert("Error", isPresented: .init(
            get: { limitsSession.error != nil },
            set: { if !$0 { limitsSession.error = nil } }
        )) {
            Button("OK") {
                limitsSession.error = nil
            }
        } message: {
            if let error = limitsSession.error {
                Text(error)
            }
        }
    }

    // MARK: - Limits Section
    private func limitsSection<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        isEmpty: Bool,
        emptyMessage: String,
        addAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    ShieldOrbView(isActive: !isEmpty, size: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.pomHeading2)
                            .foregroundColor(.pomTextPrimary)

                        Text(subtitle)
                            .font(.pomCaption)
                            .foregroundColor(.pomTextSecondary)
                    }
                }

                Spacer()

                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    addAction()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.pomShieldActive.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.pomShieldActive)
                    }
                }
            }

            // Content or empty state
            if isEmpty {
                emptyState(message: emptyMessage)
            } else {
                content()
            }
        }
        .padding(20)
        .cosmicCard(isActive: !isEmpty, cornerRadius: 16, showBorder: !isEmpty)
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: 16) {
            ShieldOrbView(isActive: false, size: 48)
                .opacity(0.6)

            Text(message)
                .font(.pomBody)
                .foregroundColor(.pomTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    LimitsView()
        .environmentObject(LimitsSession())
}
