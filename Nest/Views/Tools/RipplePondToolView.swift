import SwiftUI

/// A quiet pond where taps create soft expanding ripples among drifting fish.
struct RipplePondToolView: View {
    @State private var ripples: [Ripple] = []
    @State private var splashBursts: [SplashBurst] = []
    @State private var shimmer = false
    @State private var fishDrift = false

    private let fish: [PondFish] = [
        PondFish(size: 34, baseX: -95, baseY: 35, tint: Color(red: 0.95, green: 0.55, blue: 0.35), facingRight: true),
        PondFish(size: 28, baseX: 80, baseY: 95, tint: Color(red: 0.35, green: 0.65, blue: 0.85), facingRight: false),
        PondFish(size: 22, baseX: -20, baseY: 150, tint: Color(red: 0.75, green: 0.45, blue: 0.70), facingRight: true),
        PondFish(size: 26, baseX: 40, baseY: 55, tint: Color(red: 0.45, green: 0.75, blue: 0.65), facingRight: false)
    ]

    var body: some View {
        ZStack {
            NestBackground()

            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.28, blue: 0.42).opacity(0.7),
                    Color(red: 0.10, green: 0.18, blue: 0.30).opacity(0.45),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Ellipse()
                .fill(Color.white.opacity(shimmer ? 0.08 : 0.03))
                .frame(width: 320, height: 180)
                .blur(radius: 20)
                .offset(y: -40)

            ForEach(Array(fish.enumerated()), id: \.offset) { index, pondFish in
                PondFishView(fish: pondFish, isDrifting: fishDrift, phase: Double(index))
            }

            ForEach(ripples) { ripple in
                Circle()
                    .strokeBorder(Color.white.opacity(ripple.opacity), lineWidth: 2)
                    .frame(width: ripple.size, height: ripple.size)
                    .position(ripple.center)
            }

            ForEach(splashBursts) { burst in
                SoftParticleBurst(tint: Color(red: 0.7, green: 0.9, blue: 1.0), count: 6)
                    .position(burst.center)
                    .transition(.opacity.combined(with: .scale))
            }

            VStack {
                Text("Ripple Pond")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(NestTheme.primaryText)
                    .padding(.top, 12)

                Text("Tap the water. Let each ripple leave.")
                    .font(.subheadline)
                    .foregroundStyle(NestTheme.secondaryText)

                Spacer()

                Text("No score. Just settling.")
                    .font(.footnote)
                    .foregroundStyle(NestTheme.secondaryText)
                    .padding(.bottom, 28)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    addRipple(at: value.location)
                }
        )
        .navigationTitle("Ripple Pond")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                shimmer = true
            }
            withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
                fishDrift = true
            }
        }
    }

    /// Creates expanding ripples from a tap point.
    private func addRipple(at point: CGPoint) {
        NestHaptics.softTap()
        NestSoundPlayer.shared.play(.ripple)
        let burst = SplashBurst(center: point)
        withAnimation(.easeOut(duration: 0.2)) {
            splashBursts.append(burst)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            splashBursts.removeAll { $0.id == burst.id }
        }
        for delay in [0.0, 0.18, 0.36] {
            let ripple = Ripple(center: point, size: 12, opacity: 0.55)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                ripples.append(ripple)
                withAnimation(.easeOut(duration: 1.6)) {
                    if let index = ripples.firstIndex(where: { $0.id == ripple.id }) {
                        ripples[index].size = CGFloat.random(in: 140...220)
                        ripples[index].opacity = 0
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                    ripples.removeAll { $0.id == ripple.id }
                }
            }
        }
    }
}

/// Soft fish silhouette that drifts gently in the pond.
private struct PondFishView: View {
    let fish: PondFish
    let isDrifting: Bool
    let phase: Double

    var body: some View {
        ZStack {
            Ellipse()
                .fill(fish.tint.opacity(0.55))
                .frame(width: fish.size, height: fish.size * 0.48)

            PondFishTail()
                .fill(fish.tint.opacity(0.5))
                .frame(width: fish.size * 0.32, height: fish.size * 0.36)
                .offset(x: -fish.size * 0.42)

            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 3.5, height: 3.5)
                .offset(x: fish.size * 0.22, y: -1)
        }
        .scaleEffect(x: fish.facingRight ? 1 : -1, y: 1)
        .offset(
            x: fish.baseX + (isDrifting ? CGFloat(12 + phase * 2) : CGFloat(-10 - phase * 2)),
            y: fish.baseY + (isDrifting ? CGFloat(6 - phase) : CGFloat(-5 + phase))
        )
        .opacity(0.85)
        .accessibilityHidden(true)
    }
}

/// Simple triangular fish tail.
private struct PondFishTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct PondFish {
    let size: CGFloat
    let baseX: CGFloat
    let baseY: CGFloat
    let tint: Color
    let facingRight: Bool
}

private struct SplashBurst: Identifiable {
    let id = UUID()
    let center: CGPoint
}

private struct Ripple: Identifiable {
    let id = UUID()
    var center: CGPoint
    var size: CGFloat
    var opacity: Double
}

#Preview {
    NavigationStack {
        RipplePondToolView()
    }
}
