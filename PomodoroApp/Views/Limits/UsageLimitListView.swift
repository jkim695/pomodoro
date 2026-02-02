import SwiftUI
import DeviceActivity
import FamilyControls

/// List view showing all usage limits
struct UsageLimitListView: View {
    @EnvironmentObject var limitsSession: LimitsSession
    @State private var editingLimit: AppLimit?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(limitsSession.limits) { limit in
                UsageLimitRow(
                    limit: limit,
                    usageRecord: limitsSession.usageRecord(for: limit.id)
                ) {
                    editingLimit = limit
                } onToggle: { enabled in
                    limitsSession.toggleLimit(id: limit.id, enabled: enabled)
                } onDelete: {
                    limitsSession.deleteLimit(id: limit.id)
                }
            }
        }
        .sheet(item: $editingLimit) { limit in
            UsageLimitEditorView(limit: limit)
        }
    }
}

/// Row component for a single usage limit
struct UsageLimitRow: View {
    let limit: AppLimit
    let usageRecord: UsageRecord?
    let onEdit: () -> Void
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void
    @EnvironmentObject var rewardsManager: RewardsManager

    @State private var showDeleteConfirmation = false

    private var accentColor: Color {
        rewardsManager.equippedStyle.primaryColor
    }
    @State private var filter: DeviceActivityFilter

    init(
        limit: AppLimit,
        usageRecord: UsageRecord?,
        onEdit: @escaping () -> Void,
        onToggle: @escaping (Bool) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.limit = limit
        self.usageRecord = usageRecord
        self.onEdit = onEdit
        self.onToggle = onToggle
        self.onDelete = onDelete

        // Create filter for today's usage of this limit's apps
        let calendar = Calendar.current
        let now = Date()
        let todayInterval = calendar.dateInterval(of: .day, for: now) ?? DateInterval(start: now, end: now)

        _filter = State(initialValue: DeviceActivityFilter(
            segment: .daily(during: todayInterval),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: limit.selection.applicationTokens,
            categories: limit.selection.categoryTokens
        ))
    }

    private var usageProgress: Double {
        guard let record = usageRecord else { return 0 }
        return record.progress(limitMinutes: limit.dailyLimitMinutes)
    }

    private var remainingText: String {
        if let record = usageRecord {
            let remaining = record.remainingMinutes(limitMinutes: limit.dailyLimitMinutes)
            if remaining <= 0 {
                return "Limit reached"
            }
            return "\(AppLimit.formatMinutes(remaining)) left"
        }
        return "\(limit.formattedLimitShort) left"
    }

    private var remainingColor: Color {
        if usageProgress >= 1.0 {
            return .pomDestructive
        } else if usageProgress >= 0.75 {
            return .pomAccent
        }
        return .pomTextSecondary
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(limit.selectionCount) app\(limit.selectionCount == 1 ? "" : "s")")
                        .font(.pomBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.pomTextPrimary)

                    Text("Limit: \(limit.formattedLimit)")
                        .font(.pomCaption)
                        .foregroundColor(.pomTextSecondary)
                }

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { limit.isEnabled },
                    set: { onToggle($0) }
                ))
                .tint(accentColor)
                .labelsHidden()
            }

            // Usage progress - always shown for consistent card height
            VStack(spacing: 6) {
                // Progress bar with glow effects
                GlowingProgressBar(progress: usageProgress, showGlow: limit.isEnabled)

                // Usage text
                HStack {
                    if let record = usageRecord, record.usedMinutes > 0 {
                        Text("\(record.formattedUsedTime) used")
                            .font(.system(size: 11))
                            .foregroundColor(.pomTextTertiary)
                    } else {
                        Text("No usage today")
                            .font(.system(size: 11))
                            .foregroundColor(.pomTextTertiary)
                    }

                    Spacer()

                    Text(remainingText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(remainingColor)
                }
            }

            // DeviceActivityReport shows real-time Screen Time usage
            DeviceActivityReport(.totalUsage, filter: filter)
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .cosmicCard(isActive: limit.isEnabled, cornerRadius: 12)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(limit.selectionCount) app\(limit.selectionCount == 1 ? "" : "s") limit, \(limit.formattedLimit)")
        .accessibilityValue("\(limit.isEnabled ? "Enabled" : "Disabled"), \(remainingText)")
        .accessibilityHint("Double tap to edit")
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete Limit", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this limit?")
        }
    }
}

/// Progress bar for usage limits
struct LimitProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.pomBorder.opacity(0.5))

                // Progress fill
                if progress > 0 {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(width: max(6, min(CGFloat(progress) * geometry.size.width, geometry.size.width)))
                        .animation(.spring(response: 0.3), value: progress)
                }
            }
        }
        .frame(height: 6)
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return .pomDestructive
        } else if progress >= 0.75 {
            return .pomAccent
        } else {
            return .pomSecondary
        }
    }
}

#Preview {
    VStack {
        UsageLimitListView()
    }
    .padding()
    .background(Color.pomBackground)
    .environmentObject(LimitsSession())
}
