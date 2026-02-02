import SwiftUI

/// Canvas-based renderer for displaying hundreds of orbs efficiently
/// Uses a single render pass for all orbs instead of individual SwiftUI views
struct OrbNebulaCanvas: View {
    let orbStyleIds: [String]
    let size: CGSize
    let onOrbTapped: (Int) -> Void

    /// Base size range for orbs (varies by depth)
    private let minOrbSize: CGFloat = 14
    private let maxOrbSize: CGFloat = 28

    /// Padding from edges
    private let padding: CGFloat = 30

    /// Number of background stars
    private let starCount: Int = 200

    /// Number of spiral arms
    private let spiralArms: Int = 3

    /// Pre-calculated orb data (position, size, depth)
    private var orbData: [OrbRenderData] {
        guard size.width > 0 && size.height > 0 else { return [] }
        return orbStyleIds.enumerated().map { index, orbId in
            calculateOrbData(for: index, total: orbStyleIds.count, orbId: orbId)
        }.sorted { $0.depth < $1.depth } // Sort back-to-front for proper layering
    }

    var body: some View {
        Canvas { context, canvasSize in
            // Draw background stars first
            drawStars(context: context, size: canvasSize)

            // Draw each orb (already sorted by depth)
            for data in orbData {
                guard let style = OrbCatalog.style(for: data.orbId) else { continue }
                drawOrb(context: context, style: style, data: data)
            }
        }
        .gesture(
            SpatialTapGesture()
                .onEnded { value in
                    if let index = findOrbAt(value.location) {
                        onOrbTapped(index)
                    }
                }
        )
    }

    // MARK: - Drawing Methods

    private func drawStars(context: GraphicsContext, size: CGSize) {
        for i in 0..<starCount {
            var rng = SeededRNG(seed: UInt64(i * 54321 + 11111))
            let x = CGFloat.random(in: 0...size.width, using: &rng)
            let y = CGFloat.random(in: 0...size.height, using: &rng)
            let starSize = CGFloat.random(in: 0.5...2.0, using: &rng)
            let opacity = Double.random(in: 0.15...0.5, using: &rng)

            let rect = CGRect(
                x: x - starSize / 2,
                y: y - starSize / 2,
                width: starSize,
                height: starSize
            )
            context.fill(
                Circle().path(in: rect),
                with: .color(.white.opacity(opacity))
            )
        }
    }

    private func drawOrb(context: GraphicsContext, style: OrbStyle, data: OrbRenderData) {
        let position = data.position
        let orbSize = data.size
        let depthOpacity = data.opacity

        // Draw outer glow (more prominent)
        let glowSize = orbSize * 2.2
        let glowRect = CGRect(
            x: position.x - glowSize / 2,
            y: position.y - glowSize / 2,
            width: glowSize,
            height: glowSize
        )

        context.fill(
            Circle().path(in: glowRect),
            with: .radialGradient(
                Gradient(colors: [
                    style.glowColor.opacity(0.5 * depthOpacity),
                    style.glowColor.opacity(0.2 * depthOpacity),
                    style.glowColor.opacity(0.05 * depthOpacity),
                    Color.clear
                ]),
                center: position,
                startRadius: 0,
                endRadius: glowSize / 2
            )
        )

        // Draw main orb body
        let orbRect = CGRect(
            x: position.x - orbSize / 2,
            y: position.y - orbSize / 2,
            width: orbSize,
            height: orbSize
        )

        context.fill(
            Circle().path(in: orbRect),
            with: .radialGradient(
                Gradient(colors: [
                    style.primaryColor.opacity(0.95 * depthOpacity),
                    style.primaryColor.opacity(depthOpacity),
                    style.primaryColor.opacity(0.85 * depthOpacity)
                ]),
                center: CGPoint(x: position.x - orbSize * 0.15, y: position.y - orbSize * 0.15),
                startRadius: 0,
                endRadius: orbSize * 0.6
            )
        )

        // Draw highlight for 3D effect (only on larger/closer orbs)
        if orbSize > 18 {
            let highlightSize = orbSize * 0.35
            let highlightOffset = orbSize * 0.2
            let highlightRect = CGRect(
                x: position.x - highlightOffset - highlightSize / 2,
                y: position.y - highlightOffset - highlightSize / 2,
                width: highlightSize,
                height: highlightSize
            )

            context.fill(
                Circle().path(in: highlightRect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.6 * depthOpacity),
                        Color.white.opacity(0.2 * depthOpacity),
                        Color.clear
                    ]),
                    center: CGPoint(x: highlightRect.midX, y: highlightRect.midY),
                    startRadius: 0,
                    endRadius: highlightSize / 2
                )
            )
        }
    }

    // MARK: - Position Calculation (Spiral Galaxy)

    private func calculateOrbData(for index: Int, total: Int, orbId: String) -> OrbRenderData {
        var rng = SeededRNG(seed: UInt64(index * 12345 + 67890))

        let centerX = size.width / 2
        let centerY = size.height / 2

        // Calculate maximum radius (use most of the screen)
        let maxRadius = min(size.width, size.height) * 0.42

        // Spiral parameters
        let armIndex = index % spiralArms
        let positionInArm = index / spiralArms

        // Base angle from spiral arm
        let armBaseAngle = (2 * .pi / CGFloat(spiralArms)) * CGFloat(armIndex)

        // Progress along the spiral (0 to 1)
        let progress = CGFloat(positionInArm) / CGFloat(max(total / spiralArms, 1))

        // Radius increases with progress (with some randomization)
        let radiusNoise = CGFloat.random(in: 0.7...1.3, using: &rng)
        let radius = maxRadius * sqrt(progress) * radiusNoise

        // Angle winds as we go outward (creates spiral)
        let windingFactor: CGFloat = 2.5 // How much the spiral winds
        let angleNoise = CGFloat.random(in: -0.4...0.4, using: &rng)
        let angle = armBaseAngle + (progress * windingFactor * .pi) + angleNoise

        // Calculate position
        var x = centerX + radius * cos(angle)
        var y = centerY + radius * sin(angle)

        // Add slight random offset for organic feel
        let jitterX = CGFloat.random(in: -15...15, using: &rng)
        let jitterY = CGFloat.random(in: -15...15, using: &rng)
        x += jitterX
        y += jitterY

        // Clamp to bounds
        x = min(max(x, padding), size.width - padding)
        y = min(max(y, padding), size.height - padding)

        // Depth based on distance from center (closer to edge = further away)
        let normalizedRadius = radius / maxRadius
        let depth = normalizedRadius // 0 = center (front), 1 = edge (back)

        // Size based on depth (closer = larger)
        let sizeRange = maxOrbSize - minOrbSize
        let orbSize = maxOrbSize - (depth * sizeRange * 0.6)

        // Opacity based on depth (closer = more opaque)
        let opacity = 1.0 - (Double(depth) * 0.3)

        return OrbRenderData(
            index: index,
            orbId: orbId,
            position: CGPoint(x: x, y: y),
            size: orbSize,
            depth: depth,
            opacity: opacity
        )
    }

    // MARK: - Hit Testing

    private func findOrbAt(_ location: CGPoint) -> Int? {
        // Search in reverse (front to back) for hit testing
        for data in orbData.reversed() {
            let hitRadius = data.size * 0.6
            let distance = hypot(location.x - data.position.x, location.y - data.position.y)
            if distance <= hitRadius {
                return data.index
            }
        }
        return nil
    }
}

// MARK: - Supporting Types

private struct OrbRenderData {
    let index: Int
    let orbId: String
    let position: CGPoint
    let size: CGFloat
    let depth: CGFloat  // 0 = front, 1 = back
    let opacity: Double
}

// MARK: - Seeded Random Number Generator

/// Deterministic random number generator for consistent orb positions
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // Linear congruential generator
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Preview

#Preview {
    let sampleOrbs = Array(repeating: ["orb_default", "orb_ocean", "orb_cosmic", "orb_sunset", "orb_aurora"], count: 40).flatMap { $0 }

    return ZStack {
        Color(hex: "0A0A1A")
            .ignoresSafeArea()

        OrbNebulaCanvas(
            orbStyleIds: sampleOrbs,
            size: CGSize(width: 400, height: 800),
            onOrbTapped: { index in
                print("Tapped orb at index: \(index)")
            }
        )
    }
}
