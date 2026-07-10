import SwiftUI

/// Chill bubble game — soft floating bubbles to tap with no pressure.
struct BubbleDriftToolView: View {
    @State private var bubbles: [Bubble] = []
    @State private var softScore = 0
    @State private var spawnTask: Task<Void, Never>?
    @State private var skyPulse = false

    var body: some View {
        ZStack {
            NestBackground()
            ToolStageBackdrop(accent: Color(red: 0.7, green: 0.55, blue: 1.0))
                .offset(y: 40)
                .opacity(0.7)

            // Soft horizon haze
            Ellipse()
                .fill(Color.white.opacity(skyPulse ? 0.08 : 0.03))
                .frame(width: 360, height: 120)
                .blur(radius: 30)
                .offset(y: 180)

            ForEach(bubbles) { bubble in
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    bubble.tint.opacity(0.55),
                                    bubble.tint.opacity(0.12),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 2,
                                endRadius: bubble.size / 2
                            )
                        )
                    Circle()
                        .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: bubble.size * 0.18, height: bubble.size * 0.12)
                        .offset(x: -bubble.size * 0.18, y: -bubble.size * 0.22)
                }
                .frame(width: bubble.size, height: bubble.size)
                .position(bubble.position)
                .opacity(bubble.opacity)
                .onTapGesture {
                    pop(bubble)
                }
            }

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bubble Drift")
                            .font(.headline)
                            .foregroundStyle(NestTheme.primaryText)
                        Text("Soft pops: \(softScore)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(NestTheme.secondaryText)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()

                Text("Tap the bubbles. There’s no rush.")
                    .font(.footnote)
                    .foregroundStyle(NestTheme.secondaryText)
                    .padding(.bottom, 28)
            }
        }
        .navigationTitle("Bubble Drift")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            startSpawning()
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                skyPulse = true
            }
        }
        .onDisappear {
            spawnTask?.cancel()
            spawnTask = nil
        }
    }

    /// Begins gently spawning floating bubbles.
    private func startSpawning() {
        spawnTask?.cancel()
        spawnTask = Task {
            while !Task.isCancelled {
                await MainActor.run { spawnBubble() }
                try? await Task.sleep(for: .milliseconds(Int.random(in: 700...1_400)))
            }
        }
    }

    /// Adds one soft bubble and animates it upward.
    private func spawnBubble() {
        let size = CGFloat.random(in: 44...92)
        let startX = CGFloat.random(in: 40...340)
        let bubble = Bubble(
            size: size,
            position: CGPoint(x: startX, y: 720),
            tint: [
                Color(red: 0.65, green: 0.55, blue: 1.0),
                Color(red: 0.45, green: 0.7, blue: 1.0),
                Color(red: 0.85, green: 0.55, blue: 0.85),
                Color(red: 0.55, green: 0.85, blue: 0.75)
            ].randomElement()!,
            opacity: 0.9
        )
        bubbles.append(bubble)

        withAnimation(.easeOut(duration: Double.random(in: 5.5...8.5))) {
            if let index = bubbles.firstIndex(where: { $0.id == bubble.id }) {
                bubbles[index].position.y = -80
                bubbles[index].opacity = 0.15
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
            bubbles.removeAll { $0.id == bubble.id }
        }
    }

    /// Softly removes a tapped bubble.
    private func pop(_ bubble: Bubble) {
        softScore += 1
        withAnimation(.easeOut(duration: 0.25)) {
            bubbles.removeAll { $0.id == bubble.id }
        }
    }
}

private struct Bubble: Identifiable {
    let id = UUID()
    var size: CGFloat
    var position: CGPoint
    var tint: Color
    var opacity: Double
}

#Preview {
    NavigationStack {
        BubbleDriftToolView()
    }
}
