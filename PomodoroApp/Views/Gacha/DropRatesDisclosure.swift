import SwiftUI

/// Expandable disclosure showing gacha drop rates
struct DropRatesDisclosure: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.pomTextSecondary)

                    Text("Drop Rates")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.pomTextPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.pomTextTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pomCardBackground)
                )
            }
            .accessibilityLabel("Drop Rates")
            .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand")
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach([OrbRarity.common, .uncommon, .rare, .epic, .legendary], id: \.self) { rarity in
                        DropRateRow(rarity: rarity)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Text("Pity System")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.pomTextPrimary)

                    VStack(alignment: .leading, spacing: 4) {
                        PityInfoRow(text: "Guaranteed Rare+ every \(GachaConfig.pityRare) pulls")
                        PityInfoRow(text: "Guaranteed Epic+ every \(GachaConfig.pityEpic) pulls")
                        PityInfoRow(text: "Guaranteed Legendary every \(GachaConfig.pityLegendary) pulls")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.pomCardBackground.opacity(0.5))
                )
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct DropRateRow: View {
    let rarity: OrbRarity

    var body: some View {
        HStack {
            Circle()
                .fill(rarity.color)
                .frame(width: 10, height: 10)

            Text(rarity.displayName)
                .font(.caption)
                .foregroundColor(.pomTextPrimary)

            Spacer()

            Text("\(Int(rarity.dropRate))%")
                .font(.caption.weight(.semibold))
                .foregroundColor(.pomTextSecondary)

            Text("(\(rarity.shardsPerPull) shards)")
                .font(.caption2)
                .foregroundColor(.pomTextTertiary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rarity.displayName): \(Int(rarity.dropRate))% drop rate, \(rarity.shardsPerPull) shards per pull")
    }
}

private struct PityInfoRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.pomSecondary)

            Text(text)
                .font(.caption)
                .foregroundColor(.pomTextSecondary)
        }
    }
}

#Preview {
    VStack {
        DropRatesDisclosure()
    }
    .padding()
    .background(Color.pomBackground)
}
