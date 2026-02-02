import SwiftUI
import RealityKit

/// 3D RealityKit view for displaying the orb nebula
/// Supports orbital camera controls (drag to rotate, pinch to zoom)
/// Requires iOS 18.0+ for RealityView
@available(iOS 18.0, *)
struct OrbNebula3DView: View {
    let orbStyleIds: [String]
    let onOrbTapped: (Int) -> Void

    // Camera state
    @State private var cameraAngleX: Float = 0.2  // Slight tilt down initially
    @State private var cameraAngleY: Float = 0
    @State private var cameraDistance: Float = 6.0  // Further out to see full sphere

    // Gesture state
    @State private var lastDragValue: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0

    // Scene root for updates
    @State private var sceneRoot: Entity?

    private let spiralArms = 3

    var body: some View {
        GeometryReader { geometry in
            RealityView { content in
                // Create the nebula scene
                let root = createNebulaScene()
                root.name = "nebulaRoot"
                sceneRoot = root
                content.add(root)

                // Set initial camera position
                updateSceneTransform(root: root)
            } update: { content in
                // Update scene rotation based on camera angles
                if let root = content.entities.first(where: { $0.name == "nebulaRoot" }) {
                    updateSceneTransform(root: root)
                }
            }
            .gesture(dragGesture)
            .gesture(magnificationGesture)
            .simultaneousGesture(tapGesture(in: geometry))
        }
    }

    // MARK: - Scene Creation

    private func createNebulaScene() -> Entity {
        let root = Entity()

        // Add background starfield
        addStarfield(to: root)

        // Add orbs container (separate from stars for potential independent transforms)
        let orbsContainer = Entity()
        orbsContainer.name = "orbsContainer"

        // Create shared mesh resource for performance
        let sharedSphereMesh = MeshResource.generateSphere(radius: 0.05)

        for (index, orbId) in orbStyleIds.enumerated() {
            guard let style = OrbCatalog.style(for: orbId) else { continue }
            let orbEntity = createOrbEntity(
                index: index,
                total: orbStyleIds.count,
                style: style,
                sharedMesh: sharedSphereMesh
            )
            orbsContainer.addChild(orbEntity)
        }

        root.addChild(orbsContainer)
        return root
    }

    private func createOrbEntity(index: Int, total: Int, style: OrbStyle, sharedMesh: MeshResource) -> Entity {
        // Calculate 3D position using spiral galaxy algorithm
        let position = calculateSpiralPosition(index: index, total: total)

        // Create glowing sphere with unlit material
        var material = UnlitMaterial()
        material.color = .init(tint: UIColor(style.primaryColor))

        let entity = ModelEntity(mesh: sharedMesh, materials: [material])
        entity.position = position
        entity.name = "orb_\(index)"

        // Add outer glow sphere (larger, more transparent)
        let glowMesh = MeshResource.generateSphere(radius: 0.1)
        var glowMaterial = UnlitMaterial()
        glowMaterial.color = .init(tint: UIColor(style.glowColor).withAlphaComponent(0.25))

        let glowEntity = ModelEntity(mesh: glowMesh, materials: [glowMaterial])
        glowEntity.name = "glow_\(index)"
        entity.addChild(glowEntity)

        return entity
    }

    // MARK: - Spherical Nebula Distribution

    private func calculateSpiralPosition(index: Int, total: Int) -> SIMD3<Float> {
        var rng = SeededRNG(seed: UInt64(index * 12345 + 67890))

        // Use Fibonacci sphere distribution for even spacing, then add noise for organic feel
        let goldenRatio = (1.0 + sqrt(5.0)) / 2.0
        let i = Float(index) + 0.5

        // Fibonacci sphere algorithm for even distribution
        let theta = 2.0 * Float.pi * i / Float(goldenRatio)
        let phi = acos(1.0 - 2.0 * i / Float(total))

        // Base radius varies to create depth - inner core is denser
        let maxRadius: Float = 2.5
        let minRadius: Float = 0.3

        // Distribute radius with bias toward outer regions but some in center
        let radiusProgress = Float.random(in: 0.0...1.0, using: &rng)
        let baseRadius = minRadius + (maxRadius - minRadius) * pow(radiusProgress, 0.6)

        // Add noise to radius for organic feel
        let radiusNoise = Float.random(in: 0.85...1.15, using: &rng)
        let radius = baseRadius * radiusNoise

        // Add angular noise for less uniform appearance
        let thetaNoise = Float.random(in: -0.3...0.3, using: &rng)
        let phiNoise = Float.random(in: -0.2...0.2, using: &rng)

        let finalTheta = theta + thetaNoise
        let finalPhi = max(0.1, min(Float.pi - 0.1, phi + phiNoise))

        // Convert spherical to Cartesian coordinates
        let x = radius * sin(finalPhi) * cos(finalTheta)
        let y = radius * cos(finalPhi)
        let z = radius * sin(finalPhi) * sin(finalTheta)

        return SIMD3<Float>(x, y, z)
    }

    // MARK: - Starfield

    private func addStarfield(to root: Entity) {
        let starCount = 300
        let sharedStarMesh = MeshResource.generateSphere(radius: 0.01)

        for i in 0..<starCount {
            var rng = SeededRNG(seed: UInt64(i * 54321 + 11111))

            // Random position on a large sphere around the scene
            let radius: Float = 10.0
            let theta = Float.random(in: 0...(2 * Float.pi), using: &rng)
            let phi = acos(Float.random(in: -1...1, using: &rng))

            let x = radius * sin(phi) * cos(theta)
            let y = radius * sin(phi) * sin(theta)
            let z = radius * cos(phi)

            // Vary star size slightly
            let starSize = Float.random(in: 0.5...1.5, using: &rng)

            var material = UnlitMaterial()
            let opacity = Float.random(in: 0.3...0.8, using: &rng)
            material.color = .init(tint: .white.withAlphaComponent(CGFloat(opacity)))

            let star = ModelEntity(mesh: sharedStarMesh, materials: [material])
            star.scale = SIMD3<Float>(repeating: starSize)
            star.position = SIMD3<Float>(x, y, z)
            star.name = "star_\(i)"
            root.addChild(star)
        }
    }

    // MARK: - Scene Transform (Camera Simulation)

    private func updateSceneTransform(root: Entity) {
        // Instead of moving camera, we rotate the scene and adjust scale for zoom
        // This is simpler in RealityView on iOS

        // Create rotation from angles
        let rotationX = simd_quatf(angle: -cameraAngleX, axis: SIMD3<Float>(1, 0, 0))
        let rotationY = simd_quatf(angle: -cameraAngleY, axis: SIMD3<Float>(0, 1, 0))
        let combinedRotation = rotationY * rotationX

        root.orientation = combinedRotation

        // Adjust scale for zoom effect (closer = larger)
        let zoomScale = 6.0 / cameraDistance
        root.scale = SIMD3<Float>(repeating: Float(zoomScale))
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let deltaX = Float(value.translation.width - lastDragValue.width) * 0.008
                let deltaY = Float(value.translation.height - lastDragValue.height) * 0.008

                cameraAngleY += deltaX
                cameraAngleX = max(-Float.pi / 3, min(Float.pi / 3, cameraAngleX + deltaY))

                lastDragValue = value.translation
            }
            .onEnded { _ in
                lastDragValue = .zero
            }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let scale = value.magnification / lastScale
                let newDistance = cameraDistance / Float(scale)
                cameraDistance = max(1.5, min(15.0, newDistance))  // Allow closer zoom and further out
                lastScale = value.magnification
            }
            .onEnded { _ in
                lastScale = 1.0
            }
    }

    private func tapGesture(in geometry: GeometryProxy) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                // For tap detection, we use 2D projection approximation
                // RealityKit hit testing on iOS requires ARView which isn't available in RealityView
                // Instead, we find the closest orb to the tap location using projected coordinates

                let tapLocation = value.location
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height / 2

                // Normalize tap to -1...1 range
                let normalizedX = Float((tapLocation.x - centerX) / (geometry.size.width / 2))
                let normalizedY = Float((tapLocation.y - centerY) / (geometry.size.height / 2))

                // Find closest orb (simple distance check)
                if let closestIndex = findClosestOrb(normalizedX: normalizedX, normalizedY: normalizedY) {
                    onOrbTapped(closestIndex)
                }
            }
    }

    private func findClosestOrb(normalizedX: Float, normalizedY: Float) -> Int? {
        var closestIndex: Int?
        var closestDistance: Float = Float.infinity

        // Apply inverse rotation to get tap ray in scene space
        let rotationX = simd_quatf(angle: cameraAngleX, axis: SIMD3<Float>(1, 0, 0))
        let rotationY = simd_quatf(angle: cameraAngleY, axis: SIMD3<Float>(0, 1, 0))

        for (index, _) in orbStyleIds.enumerated() {
            let position3D = calculateSpiralPosition(index: index, total: orbStyleIds.count)

            // Apply rotation to orb position
            let rotatedPosition = rotationY.act(rotationX.act(position3D))

            // Simple orthographic projection for hit testing
            let projectedX = rotatedPosition.x / cameraDistance
            let projectedY = rotatedPosition.y / cameraDistance

            // Distance from tap to projected orb position
            let distance = hypot(projectedX - normalizedX, projectedY - normalizedY)

            // Check if within tap radius and closer than previous closest
            let tapRadius: Float = 0.15  // Generous tap area
            if distance < tapRadius && distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }

        return closestIndex
    }
}

// MARK: - Preview

@available(iOS 18.0, *)
#Preview {
    let sampleOrbs = Array(repeating: ["orb_default", "orb_ocean", "orb_cosmic", "orb_sunset", "orb_aurora"], count: 40).flatMap { $0 }

    return ZStack {
        Color(hex: "0A0A1A")
            .ignoresSafeArea()

        OrbNebula3DView(
            orbStyleIds: sampleOrbs,
            onOrbTapped: { index in
                print("Tapped orb at index: \(index)")
            }
        )
    }
}
