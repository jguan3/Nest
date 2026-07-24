import SwiftUI

/// Guided breathing with a circle that expands on inhale and shrinks on exhale.
struct BreathingToolView: View {
    @State private var isRunning = false
    @State private var isInhale = true
    @State private var scale: CGFloat = 0.55
    @State private var ringPulse = false
    @State private var cycleTask: Task<Void, Never>?

    private let inhaleSeconds: Double = 4
    private let exhaleSeconds: Double = 4

    var body: some View {
        ZStack {
            NestBackground()

            ToolStageBackdrop(accent: Color(red: 0.55, green: 0.7, blue: 1.0))
                .offset(y: -20)

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text(isRunning ? (isInhale ? "Inhale" : "Exhale") : "Ready when you are")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(NestTheme.primaryText)
                        .animation(.easeInOut(duration: 0.3), value: isInhale)

                    Text(isRunning ? "Follow the circle. Nowhere else to be." : "4 seconds in · 4 seconds out")
                        .font(.subheadline)
                        .foregroundStyle(NestTheme.secondaryText)
                }

                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .strokeBorder(Color.white.opacity(0.08 - Double(index) * 0.015), lineWidth: 1)
                            .frame(width: 160 + CGFloat(index) * 48, height: 160 + CGFloat(index) * 48)
                            .scaleEffect(ringPulse ? 1.04 : 0.96)
                    }

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.72, green: 0.62, blue: 1.0).opacity(0.55),
                                    Color(red: 0.35, green: 0.5, blue: 0.95).opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 150
                            )
                        )
                        .frame(width: 260, height: 260)
                        .scaleEffect(scale)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.55), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 170, height: 170)
                        .scaleEffect(scale)

                    Image(systemName: isInhale ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                        .font(.title3)
                        .foregroundStyle(NestTheme.primaryText.opacity(0.7))
                        .opacity(isRunning ? 1 : 0.35)
                }
                .frame(height: 300)

                HStack(spacing: 18) {
                    breathMetric(title: "In", value: "4s")
                    breathMetric(title: "Out", value: "4s")
                    breathMetric(title: "Pace", value: "Soft")
                }
                .padding(.horizontal, 24)

                Button {
                    if isRunning { stopBreathing() } else { startBreathing() }
                } label: {
                    Text(isRunning ? "Stop" : "Begin")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: 200)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(NestTheme.accentGradient))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Guided Breathing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                ringPulse = true
            }
        }
        .onDisappear { stopBreathing() }
    }

    private func breathMetric(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(NestTheme.secondaryText)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NestTheme.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(NestTheme.cardBackground)
        )
    }

    /// Starts the inhale/exhale animation loop.
    private func startBreathing() {
        NestSoundPlayer.shared.play(.chime)
        isRunning = true
        cycleTask?.cancel()
        cycleTask = Task {
            while !Task.isCancelled {
                await animatePhase(inhale: true)
                guard !Task.isCancelled else { break }
                await animatePhase(inhale: false)
            }
        }
    }

    /// Stops breathing animation and resets the circle.
    private func stopBreathing() {
        cycleTask?.cancel()
        cycleTask = nil
        isRunning = false
        isInhale = true
        withAnimation(.easeInOut(duration: 0.4)) {
            scale = 0.55
        }
    }

    /// Animates one inhale or exhale phase.
    private func animatePhase(inhale: Bool) async {
        await MainActor.run {
            isInhale = inhale
            NestSoundPlayer.shared.play(inhale ? .breathIn : .breathOut)
            withAnimation(.easeInOut(duration: inhale ? inhaleSeconds : exhaleSeconds)) {
                scale = inhale ? 1.15 : 0.55
            }
        }
        try? await Task.sleep(for: .seconds(inhale ? inhaleSeconds : exhaleSeconds))
    }
}

#Preview {
    NavigationStack {
        BreathingToolView()
    }
}
