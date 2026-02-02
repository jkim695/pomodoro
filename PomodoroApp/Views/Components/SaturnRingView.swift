import SwiftUI

/// Saturn-style elliptical rings for orbs
/// Two rings slanted at opposite angles, spinning in place like Saturn's rings
struct SaturnRingView: View {
    let size: CGFloat
    let color: Color
    let starLevel: Int

    @State private var spin1: Double = 0
    @State private var spin2: Double = 0

    // Ring properties scale with star level
    private var ringThickness: CGFloat {
        switch starLevel {
        case 1: return 1.5
        case 2: return 2
        default: return 2.5
        }
    }

    private var ringScale: CGFloat {
        switch starLevel {
        case 1: return 1.3
        case 2: return 1.4
        default: return 1.5
        }
    }

    private var ringOpacity: Double {
        switch starLevel {
        case 1: return 0.6
        case 2: return 0.7
        default: return 0.8
        }
    }

    // Spin speed increases with star level
    private var spinDuration: Double {
        switch starLevel {
        case 1: return 20
        case 2: return 15
        case 3: return 12
        case 4: return 10
        default: return 8
        }
    }

    var body: some View {
        ZStack {
            // First ring - slanted 45 degrees
            spinningRing(slant: 45, spin: spin1)

            // Second ring - slanted -45 degrees (only for level 2+)
            if starLevel >= 2 {
                spinningRing(slant: -45, spin: spin2)
                    .opacity(0.7)
            }
        }
        .onAppear {
            startSpinning()
        }
    }

    private func spinningRing(slant: Double, spin: Double) -> some View {
        // Create a ring with gradient that will spin
        ZStack {
            // Use multiple arcs to create the illusion of a spinning ring with varying brightness
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .trim(from: CGFloat(i) * 0.25, to: CGFloat(i) * 0.25 + 0.25)
                    .stroke(
                        color.opacity(ringOpacity * (0.4 + Double(i) * 0.2)),
                        lineWidth: ringThickness
                    )
            }
        }
        .frame(width: size * ringScale, height: size * ringScale)
        // First spin the ring in its own plane (like a record spinning)
        .rotationEffect(.degrees(spin))
        // Then squash it to look like a tilted ring
        .scaleEffect(x: 1, y: 0.25)
        // Then apply the slant angle
        .rotationEffect(.degrees(slant))
        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 1)
    }

    private func startSpinning() {
        // First ring spins clockwise
        withAnimation(.linear(duration: spinDuration).repeatForever(autoreverses: false)) {
            spin1 = 360
        }

        // Second ring spins counter-clockwise at slightly different speed
        if starLevel >= 2 {
            withAnimation(.linear(duration: spinDuration * 1.2).repeatForever(autoreverses: false)) {
                spin2 = -360
            }
        }
    }
}

#Preview {
    VStack(spacing: 60) {
        HStack(spacing: 40) {
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 80, height: 80)
                SaturnRingView(size: 80, color: .orange, starLevel: 1)
            }
            Text("1 Star")
        }

        HStack(spacing: 40) {
            ZStack {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 80, height: 80)
                SaturnRingView(size: 80, color: .purple, starLevel: 2)
            }
            Text("2 Stars")
        }

        HStack(spacing: 40) {
            ZStack {
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 80, height: 80)
                SaturnRingView(size: 80, color: .cyan, starLevel: 5)
            }
            Text("5 Stars")
        }
    }
    .padding()
    .background(Color.black)
    .foregroundColor(.white)
}
