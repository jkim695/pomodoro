import SpriteKit

/// SpriteKit scene for rendering pixel art avatar animations
class AvatarScene: SKScene {

    // MARK: - Properties

    private var avatarSprite: SKSpriteNode!
    private var currentState: AvatarState = .sleeping

    /// Fallback color used when texture assets are not found
    private let fallbackColor = SKColor(red: 255/255, green: 200/255, blue: 180/255, alpha: 1.0) // Peach color

    /// Frame rate for animations (seconds per frame) - 1.5x speed
    private let animationTimePerFrame: TimeInterval = 0.1

    // MARK: - Initialization

    override init(size: CGSize) {
        super.init(size: size)
        setupScene()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupScene()
    }

    private func setupScene() {
        backgroundColor = .clear
        scaleMode = .aspectFit

        // Create the main avatar sprite
        avatarSprite = SKSpriteNode(color: fallbackColor, size: CGSize(width: 64, height: 64))
        avatarSprite.position = CGPoint(x: size.width / 2, y: size.height / 2)

        // Ensure pixel art stays crisp when scaled
        avatarSprite.texture?.filteringMode = .nearest

        addChild(avatarSprite)

        // Start with idle animation
        updateState(.sleeping)
    }

    // MARK: - Public API

    /// Updates the avatar's animation state
    /// - Parameter state: The new avatar state to transition to
    func updateState(_ state: AvatarState) {
        guard state != currentState || avatarSprite.action(forKey: "animation") == nil else { return }
        currentState = state

        // Stop any existing animation
        avatarSprite.removeAction(forKey: "animation")

        // Get textures for the new state
        let textures = loadTextures(for: state)

        if textures.isEmpty {
            // Fallback: Use colored square with simple animation
            runFallbackAnimation(for: state)
        } else {
            // Run texture-based animation
            runTextureAnimation(with: textures, for: state)
        }
    }

    /// Resizes the scene and repositions the avatar
    func resize(to newSize: CGSize) {
        size = newSize
        avatarSprite.position = CGPoint(x: newSize.width / 2, y: newSize.height / 2)

        // Scale avatar to fit within scene while maintaining aspect ratio (3x size)
        let scale = min(newSize.width, newSize.height) / 64.0 * 2.4
        avatarSprite.setScale(scale)
    }

    // MARK: - Texture Loading

    /// Loads animation frame textures for the given state
    /// Asset naming convention: "avatar_[state]_[frame]" (e.g., "avatar_idle_0")
    private func loadTextures(for state: AvatarState) -> [SKTexture] {
        let prefix = texturePrefix(for: state)
        var textures: [SKTexture] = []

        // Try to load frames 0-31 (or until we don't find any more)
        for frame in 0...31 {
            let textureName = "\(prefix)_\(frame)"

            // Check if asset exists in the asset catalog
            if let _ = UIImage(named: textureName) {
                let texture = SKTexture(imageNamed: textureName)
                texture.filteringMode = .nearest // Crucial for crisp pixel art
                textures.append(texture)
            } else {
                // Stop looking if we don't find a frame
                break
            }
        }

        return textures
    }

    /// Returns the texture name prefix for a given state
    private func texturePrefix(for state: AvatarState) -> String {
        switch state {
        case .sleeping:
            return "avatar_idle"
        case .working:
            return "avatar_focus"
        case .celebrating:
            return "avatar_celebrate"
        case .disappointed:
            return "avatar_sad"
        }
    }

    // MARK: - Animation

    /// Runs texture-based animation
    private func runTextureAnimation(with textures: [SKTexture], for state: AvatarState) {
        let animateAction = SKAction.animate(with: textures, timePerFrame: animationTimePerFrame)
        let repeatAction = SKAction.repeatForever(animateAction)

        avatarSprite.run(repeatAction, withKey: "animation")
    }

    /// Runs a fallback animation when textures are not available
    private func runFallbackAnimation(for state: AvatarState) {
        // Reset to fallback square
        avatarSprite.texture = nil
        avatarSprite.color = fallbackColor
        avatarSprite.size = CGSize(width: 64, height: 64)

        let animation: SKAction

        switch state {
        case .sleeping:
            // Gentle breathing/pulsing animation
            let scaleUp = SKAction.scale(to: 1.05, duration: 1.0)
            let scaleDown = SKAction.scale(to: 1.0, duration: 1.0)
            scaleUp.timingMode = .easeInEaseOut
            scaleDown.timingMode = .easeInEaseOut
            animation = SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))

        case .working:
            // Subtle bounce animation
            let moveUp = SKAction.moveBy(x: 0, y: 3, duration: 0.4)
            let moveDown = SKAction.moveBy(x: 0, y: -3, duration: 0.4)
            moveUp.timingMode = .easeInEaseOut
            moveDown.timingMode = .easeInEaseOut
            animation = SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))

        case .celebrating:
            // Bouncy jump animation
            let jump = SKAction.moveBy(x: 0, y: 10, duration: 0.2)
            let fall = SKAction.moveBy(x: 0, y: -10, duration: 0.2)
            let scaleUp = SKAction.scale(to: 1.1, duration: 0.2)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
            jump.timingMode = .easeOut
            fall.timingMode = .easeIn

            let jumpSequence = SKAction.sequence([jump, fall])
            let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
            let bounce = SKAction.group([jumpSequence, scaleSequence])
            animation = SKAction.repeatForever(bounce)

            // Also change color to indicate celebration
            avatarSprite.color = SKColor(red: 180/255, green: 210/255, blue: 180/255, alpha: 1.0) // Sage color

        case .disappointed:
            // Shake animation
            let shakeLeft = SKAction.moveBy(x: -4, y: 0, duration: 0.05)
            let shakeRight = SKAction.moveBy(x: 8, y: 0, duration: 0.1)
            let shakeBack = SKAction.moveBy(x: -4, y: 0, duration: 0.05)
            let pause = SKAction.wait(forDuration: 1.0)
            let shakeSequence = SKAction.sequence([shakeLeft, shakeRight, shakeBack, pause])
            animation = SKAction.repeatForever(shakeSequence)

            // Slightly darker color to indicate sadness
            avatarSprite.color = SKColor(red: 200/255, green: 180/255, blue: 170/255, alpha: 1.0)
        }

        avatarSprite.run(animation, withKey: "animation")
    }
}
