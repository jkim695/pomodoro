import SwiftUI
import SpriteKit

struct AvatarView: View {
    let state: AvatarState
    let size: CGFloat

    @State private var scene: AvatarScene

    init(state: AvatarState, size: CGFloat = 100) {
        self.state = state
        self.size = size

        // Initialize the scene with the given size
        let avatarScene = AvatarScene(size: CGSize(width: size, height: size))
        avatarScene.scaleMode = .aspectFit
        _scene = State(initialValue: avatarScene)
    }

    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: size, height: size)
            .onChange(of: state) { newState in
                scene.updateState(newState)
            }
            .onAppear {
                scene.resize(to: CGSize(width: size, height: size))
                scene.updateState(state)
            }
    }
}

#Preview {
    VStack(spacing: 40) {
        HStack(spacing: 30) {
            VStack {
                AvatarView(state: .sleeping, size: 100)
                Text("Sleeping").font(.caption)
            }
            VStack {
                AvatarView(state: .working, size: 100)
                Text("Working").font(.caption)
            }
        }
        HStack(spacing: 30) {
            VStack {
                AvatarView(state: .celebrating, size: 100)
                Text("Celebrating").font(.caption)
            }
            VStack {
                AvatarView(state: .disappointed, size: 100)
                Text("Disappointed").font(.caption)
            }
        }
    }
    .padding()
    .background(Color.pomCream)
}
