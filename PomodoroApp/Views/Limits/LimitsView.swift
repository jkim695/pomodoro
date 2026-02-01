import SwiftUI

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
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.pomPrimary)

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
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.pomPrimary)
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pomCardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(.pomTextTertiary)

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
