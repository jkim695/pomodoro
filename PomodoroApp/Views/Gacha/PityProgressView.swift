import SwiftUI

/// Shows progress toward guaranteed pity pulls
struct PityProgressView: View {
    let counter: GachaPityCounter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pity Progress")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.pomTextPrimary)

            HStack(spacing: 16) {
                PityProgressItem(
                    label: "Rare+",
                    current: counter.pullsSinceRare,
                    threshold: GachaConfig.pityRare,
                    color: OrbRarity.rare.color
                )

                PityProgressItem(
                    label: "Epic+",
                    current: counter.pullsSinceEpic,
                    threshold: GachaConfig.pityEpic,
                    color: OrbRarity.epic.color
                )

                PityProgressItem(
                    label: "Legendary",
                    current: counter.pullsSinceLegendary,
                    threshold: GachaConfig.pityLegendary,
                    color: OrbRarity.legendary.color
                )
            }

            Text("Total pulls: \(counter.totalPulls)")
                .font(.caption)
                .foregroundColor(.pomTextTertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pomCardBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pity Progress. \(counter.pullsSinceRare) pulls since Rare, \(GachaConfig.pityRare - counter.pullsSinceRare) until guaranteed. \(counter.pullsSinceEpic) pulls since Epic, \(GachaConfig.pityEpic - counter.pullsSinceEpic) until guaranteed. \(counter.pullsSinceLegendary) pulls since Legendary, \(GachaConfig.pityLegendary - counter.pullsSinceLegendary) until guaranteed. Total pulls: \(counter.totalPulls)")
    }
}

private struct PityProgressItem: View {
    let label: String
    let current: Int
    let threshold: Int
    let color: Color

    private var progress: Double {
        Double(current) / Double(threshold)
    }

    private var remaining: Int {
        max(threshold - current, 0)
    }

    var body: some View {
        VStack(spacing: 6) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(remaining)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.pomTextPrimary)
            }
            .frame(width: 44, height: 44)

            Text(label)
                .font(.caption2)
                .foregroundColor(.pomTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(remaining) pulls until guaranteed")
    }
}

#Preview {
    VStack {
        PityProgressView(counter: GachaPityCounter(
            pullsSinceRare: 15,
            pullsSinceEpic: 30,
            pullsSinceLegendary: 45,
            totalPulls: 45
        ))

        PityProgressView(counter: GachaPityCounter(
            pullsSinceRare: 29,
            pullsSinceEpic: 49,
            pullsSinceLegendary: 99,
            totalPulls: 99
        ))
    }
    .padding()
    .background(Color.pomBackground)
}
