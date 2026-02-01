import SwiftUI
import FamilyControls

/// Editor view for creating or editing a usage limit
struct UsageLimitEditorView: View {
    @EnvironmentObject var limitsSession: LimitsSession
    @Environment(\.dismiss) private var dismiss

    let limit: AppLimit?

    @State private var selection = FamilyActivitySelection()
    @State private var dailyLimitMinutes: Int = 30
    @State private var showAppSelection = false

    private var isEditing: Bool { limit != nil }

    init(limit: AppLimit?) {
        self.limit = limit

        if let limit = limit {
            _selection = State(initialValue: limit.selection)
            _dailyLimitMinutes = State(initialValue: limit.dailyLimitMinutes)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pomBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Apps
                        editorSection(title: "Apps to Limit", icon: "shield.fill") {
                            VStack(spacing: 12) {
                                let appCount = selection.applicationTokens.count + selection.categoryTokens.count

                                HStack {
                                    Text("\(appCount) item\(appCount == 1 ? "" : "s") selected")
                                        .font(.pomBody)
                                        .foregroundColor(.pomTextPrimary)
                                    Spacer()
                                }

                                Button {
                                    showAppSelection = true
                                } label: {
                                    HStack {
                                        Text("Select Apps")
                                            .font(.pomButton)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundColor(.pomShieldActive)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.pomShieldActive.opacity(0.1))
                                    )
                                }
                            }
                        }

                        // Daily Limit
                        editorSection(title: "Daily Limit", icon: "hourglass") {
                            VStack(spacing: 16) {
                                Text(AppLimit.formatMinutes(dailyLimitMinutes))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.pomTextPrimary)

                                durationPicker
                            }
                        }

                        // Info
                        infoSection

                        // Save Button
                        RoundedButton(isEditing ? "Save Changes" : "Create Limit", style: .primary) {
                            saveLimit()
                        }
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(isEditing ? "Edit Limit" : "New Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.pomTextSecondary)
                }
            }
        }
        .sheet(isPresented: $showAppSelection) {
            LimitAppSelectionView(selection: $selection)
        }
    }

    // MARK: - Duration Picker
    private var durationPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
            ForEach(AppLimit.presets, id: \.self) { minutes in
                let isSelected = dailyLimitMinutes == minutes
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    dailyLimitMinutes = minutes
                } label: {
                    Text(AppLimit.formatMinutes(minutes))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(isSelected ? .white : .pomTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.pomShieldActive.opacity(0.3))
                                        .blur(radius: 4)
                                        .padding(-2)
                                }
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? Color.pomShieldActive : Color.pomCardBackgroundAlt)
                                    .shadow(
                                        color: isSelected ? Color.pomShieldActive.opacity(0.4) : .clear,
                                        radius: 6
                                    )
                            }
                        )
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dailyLimitMinutes)
            }
        }
    }

    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.pomShieldActive)
                Text("How it works")
                    .font(.pomBody)
                    .fontWeight(.medium)
                    .foregroundColor(.pomTextPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                bulletPoint("Usage is tracked throughout the day")
                bulletPoint("Apps are blocked when limit is reached")
                bulletPoint("Limit resets at midnight")
            }
        }
        .padding(16)
        .cosmicCard(isActive: false, cornerRadius: 16, showBorder: false)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.pomShieldActive)
            Text(text)
                .font(.pomCaption)
                .foregroundColor(.pomTextSecondary)
        }
    }

    // MARK: - Editor Section
    private func editorSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.pomShieldActive)

                Text(title)
                    .font(.pomBody)
                    .fontWeight(.medium)
                    .foregroundColor(.pomTextPrimary)
            }

            content()
        }
        .padding(16)
        .cosmicCard(isActive: false, cornerRadius: 16, showBorder: false)
    }

    // MARK: - Computed Properties
    private var canSave: Bool {
        !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
    }

    // MARK: - Actions
    private func saveLimit() {
        if let existingLimit = limit {
            // Update existing
            var updated = existingLimit
            updated.selection = selection
            updated.dailyLimitMinutes = dailyLimitMinutes
            limitsSession.updateLimit(updated)
        } else {
            // Create new
            let newLimit = AppLimit(
                selection: selection,
                dailyLimitMinutes: dailyLimitMinutes
            )
            limitsSession.addLimit(newLimit)
        }

        dismiss()
    }
}

/// App selection view for usage limits
struct LimitAppSelectionView: View {
    @Binding var selection: FamilyActivitySelection
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pomBackground
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ShieldOrbView(isActive: true, size: 48)

                        Text("Apps to Limit")
                            .font(.pomHeading2)
                            .foregroundColor(.pomTextPrimary)

                        Text("Select apps and categories to set a daily usage limit for.")
                            .font(.pomBody)
                            .foregroundColor(.pomTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)

                    FamilyActivityPicker(selection: $selection)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.pomCardBackground)
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.pomButton)
                    .foregroundColor(.pomShieldActive)
                }
            }
        }
    }
}

#Preview {
    UsageLimitEditorView(limit: nil)
        .environmentObject(LimitsSession())
}
