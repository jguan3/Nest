import SwiftUI

/// A quiet pond where taps create soft expanding ripples.
struct RipplePondToolView: View {
    @State private var ripples: [Ripple] = []
    @State private var shimmer = false
    @State private var lilyDrift = false

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

            // Water sheen
            Ellipse()
                .fill(Color.white.opacity(shimmer ? 0.08 : 0.03))
                .frame(width: 320, height: 180)
                .blur(radius: 20)
                .offset(y: -40)

            // Soft lily pads
            ForEach(0..<3, id: \.self) { index in
                Ellipse()
                    .fill(Color(red: 0.35, green: 0.55, blue: 0.42).opacity(0.45))
                    .frame(width: 70 - CGFloat(index) * 8, height: 28)
                    .overlay(
                        Ellipse()
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .offset(
                        x: CGFloat([-90, 70, 10][index]) + (lilyDrift ? 8 : -6),
                        y: CGFloat([40, 90, 150][index])
                    )
            }

            ForEach(ripples) { ripple in
                Circle()
                    .strokeBorder(Color.white.opacity(ripple.opacity), lineWidth: 2)
                    .frame(width: ripple.size, height: ripple.size)
                    .position(ripple.center)
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
                lilyDrift = true
            }
        }
    }

    /// Creates expanding ripples from a tap point.
    private func addRipple(at point: CGPoint) {
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
