import SwiftUI

/// Brief floating sparkles used as soft visual feedback in tools.
struct SoftParticleBurst: View {
    var tint: Color = .white
    var count: Int = 6

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(tint.opacity(0.75 - Double(index % 3) * 0.15))
                    .frame(width: CGFloat(4 + index % 3), height: CGFloat(4 + index % 3))
                    .offset(
                        x: CGFloat([-28, -12, 8, 22, -18, 16][index % 6]),
                        y: CGFloat([-20, 10, -28, 4, 18, -8][index % 6])
                    )
            }
        }
        .allowsHitTesting(false)
    }
}
