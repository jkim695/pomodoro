import SwiftUI

/// Small badge displaying star count for orb cards
struct StarBadge: View {
    let level: Int

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<level, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
            }
        }
        .foregroundStyle(
            LinearGradient(
                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
        )
        .overlay(
            Capsule()
                .stroke(Color(hex: "FFD700").opacity(0.4), lineWidth: 0.5)
        )
    }
}

/// Larger star display for detail views
struct StarLevelDisplay: View {
    let level: Int
    let maxLevel: Int

    init(level: Int, maxLevel: Int = 5) {
        self.level = level
        self.maxLevel = maxLevel
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxLevel, id: \.self) { index in
                Image(systemName: index < level ? "star.fill" : "star")
                    .font(.system(size: 16))
                    .foregroundStyle(
                        index < level
                            ? LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Star Badges (small)")
            .font(.headline)

        HStack(spacing: 16) {
            StarBadge(level: 1)
            StarBadge(level: 2)
            StarBadge(level: 3)
            StarBadge(level: 4)
            StarBadge(level: 5)
        }

        Divider()

        Text("Star Level Display (large)")
            .font(.headline)

        VStack(spacing: 12) {
            StarLevelDisplay(level: 1)
            StarLevelDisplay(level: 3)
            StarLevelDisplay(level: 5)
        }
    }
    .padding()
    .background(Color.pomBackground)
}
