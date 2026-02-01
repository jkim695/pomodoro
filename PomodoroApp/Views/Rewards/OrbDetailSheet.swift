import SwiftUI

/// Detail sheet for viewing and purchasing/equipping an orb style
struct OrbDetailSheet: View {
    let style: OrbStyle
    @EnvironmentObject var rewardsManager: RewardsManager
    @Environment(\.dismiss) private var dismiss

    @State private var showPurchaseError = false
    @State private var purchaseError: PurchaseError?
    @State private var isPurchasing = false

    private var isOwned: Bool {
        rewardsManager.collection.owns(style.id)
    }

    private var isEquipped: Bool {
        rewardsManager.collection.isEquipped(style.id)
    }

    private var canAfford: Bool {
        rewardsManager.balance.current >= style.price
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.pomTextTertiary)
                }
            }
            .padding(.horizontal)

            // Large orb preview
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [style.glowColor.opacity(0.5), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                // Main orb
                GradientOrbView(state: .idle, size: 120, style: style)
            }
            .padding(.vertical, 16)

            // Info
            VStack(spacing: 8) {
                Text(style.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.pomTextPrimary)

                // Rarity badge
                Text(style.rarity.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(style.rarity.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(style.rarity.color.opacity(0.15))
                    )

                Text(style.description)
                    .font(.subheadline)
                    .foregroundColor(.pomTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 4)
            }

            Spacer()

            // Action button
            VStack(spacing: 12) {
                if isOwned {
                    if isEquipped {
                        // Already equipped
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Currently Equipped")
                        }
                        .font(.headline)
                        .foregroundColor(.pomSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.pomSecondary.opacity(0.15))
                        )
                    } else {
                        // Equip button
                        Button {
                            rewardsManager.equip(style)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dismiss()
                        } label: {
                            Text("Equip")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.pomPrimary)
                                )
                        }
                    }
                } else {
                    // Purchase button
                    Button {
                        purchaseStyle()
                    } label: {
                        HStack(spacing: 8) {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                Text("\(style.price)")
                                Text("Purchase")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(canAfford ? .white : .pomTextTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canAfford ? Color.pomPrimary : Color.pomCardBackgroundAlt)
                        )
                    }
                    .disabled(!canAfford || isPurchasing)

                    if !canAfford {
                        Text("Not enough Stardust")
                            .font(.caption)
                            .foregroundColor(.pomDestructive)
                    }
                }

                // Current balance
                HStack {
                    Text("Your balance:")
                        .font(.caption)
                        .foregroundColor(.pomTextSecondary)
                    StardustBadge(amount: rewardsManager.balance.current, size: .small)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.pomBackground)
        .alert("Purchase Failed", isPresented: $showPurchaseError) {
            Button("OK") { }
        } message: {
            Text(purchaseError?.localizedDescription ?? "Unknown error")
        }
    }

    private func purchaseStyle() {
        isPurchasing = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Small delay for feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let result = rewardsManager.purchase(style)

            isPurchasing = false

            switch result {
            case .success:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                // Auto-equip after purchase
                rewardsManager.equip(style)
                dismiss()
            case .failure(let error):
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                purchaseError = error
                showPurchaseError = true
            }
        }
    }
}

#Preview {
    OrbDetailSheet(style: OrbCatalog.all[4])
        .environmentObject(RewardsManager.shared)
}
