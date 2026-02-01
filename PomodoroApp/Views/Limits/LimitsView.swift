import SwiftUI

/// Main view for the Limits tab - shows time schedules and usage limits
struct LimitsView: View {
    @EnvironmentObject var limitsSession: LimitsSession
    @State private var showAddSchedule = false
    @State private var showAddLimit = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pomCream
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Time Schedules Section
                        limitsSection(
                            title: "Time Schedules",
                            subtitle: "Block apps during specific hours",
                            icon: "clock.fill",
                            isEmpty: limitsSession.schedules.isEmpty,
                            emptyMessage: "No time schedules yet",
                            addAction: { showAddSchedule = true }
                        ) {
                            TimeScheduleListView()
                        }

                        // Usage Limits Section
                        limitsSection(
                            title: "Daily Limits",
                            subtitle: "Limit how long you use certain apps",
                            icon: "hourglass",
                            isEmpty: limitsSession.limits.isEmpty,
                            emptyMessage: "No usage limits yet",
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
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.pomPeach)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.pomHeading)
                            .foregroundColor(.pomBrown)

                        Text(subtitle)
                            .font(.pomCaption)
                            .foregroundColor(.pomLightBrown)
                    }
                }

                Spacer()

                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    addAction()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.pomPeach)
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
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.pomBrown.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.pomBody)
                .foregroundColor(.pomLightBrown)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    LimitsView()
        .environmentObject(LimitsSession())
}
