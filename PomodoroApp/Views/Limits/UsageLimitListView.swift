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

    @State private var showDeleteConfirmation = false
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

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(limit.selectionCount) app\(limit.selectionCount == 1 ? "" : "s")")
                        .font(.pomBody)
                        .fontWeight(.medium)
                        .foregroundColor(.pomBrown)

                    Text("Limit: \(limit.formattedLimit)")
                        .font(.pomCaption)
                        .foregroundColor(.pomLightBrown)
                }

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { limit.isEnabled },
                    set: { onToggle($0) }
                ))
                .tint(.pomPeach)
                .labelsHidden()
            }

            // Show actual Screen Time usage from DeviceActivityReport
            if limit.isEnabled {
                DeviceActivityReport(.totalUsage, filter: filter)
                    .frame(minHeight: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pomCream)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
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
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.pomCream.opacity(0.5))

                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(progressColor)
                    .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width))
                    .animation(.spring(response: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.75 {
            return .orange
        } else {
            return .pomSage
        }
    }
}

#Preview {
    VStack {
        UsageLimitListView()
    }
    .padding()
    .environmentObject(LimitsSession())
}
