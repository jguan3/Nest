import SwiftUI

/// Soft bubble game with difficulty, a short timed round, and a calm score.
struct BubbleDriftToolView: View {
    @State private var bubbles: [Bubble] = []
    @State private var softScore = 0
    @State private var spawnTask: Task<Void, Never>?
    @State private var timerTask: Task<Void, Never>?
    @State private var skyPulse = false
    @State private var difficulty: BubbleDifficulty = .easy
    @State private var phase: GamePhase = .ready
    @State private var secondsRemaining = 30
    @State private var lastPopPoints: Int?
    @State private var popFlashOpacity = 0.0
    @State private var popBursts: [PopBurst] = []

    private enum GamePhase {
        case ready
        case playing
        case finished
    }

    var body: some View {
        ZStack {
            NestBackground()
            ToolStageBackdrop(accent: Color(red: 0.7, green: 0.55, blue: 1.0))
                .offset(y: 40)
                .opacity(0.7)

            Ellipse()
                .fill(Color.white.opacity(skyPulse ? 0.08 : 0.03))
                .frame(width: 360, height: 120)
                .blur(radius: 30)
                .offset(y: 180)

            ForEach(bubbles) { bubble in
                bubbleView(bubble)
                    .position(bubble.position)
                    .opacity(bubble.opacity)
                    .onTapGesture {
                        guard phase == .playing else { return }
                        pop(bubble)
                    }
            }

            ForEach(popBursts) { burst in
                SoftParticleBurst(tint: Color(red: 0.85, green: 0.75, blue: 1.0), count: 5)
                    .position(burst.center)
            }

            VStack(spacing: 16) {
                header

                if phase == .ready {
                    difficultyPicker
                    Spacer()
                    Button("Start 30s") { startRound() }
                        .buttonStyle(NestPrimaryButtonStyle())
                        .padding(.bottom, 28)
                } else if phase == .finished {
                    Spacer()
                    finishedCard
                    Spacer()
                    Button("Play again") { resetToReady() }
                        .buttonStyle(NestPrimaryButtonStyle())
                        .padding(.bottom, 28)
                } else {
                    Spacer()
                    Text("Tap the bubbles.")
                        .font(.footnote)
                        .foregroundStyle(NestTheme.secondaryText)
                        .padding(.bottom, 28)
                }
            }
        }
        .navigationTitle("Bubble Drift")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                skyPulse = true
            }
        }
        .onDisappear {
            stopRound()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bubble Drift")
                    .font(.headline)
                    .foregroundStyle(NestTheme.primaryText)

                if phase == .playing || phase == .finished {
                    Text("Score: \(softScore)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(NestTheme.secondaryText)
                } else {
                    Text("Pick a pace, then play for 30 seconds.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(NestTheme.secondaryText)
                }
            }

            Spacer()

            if phase == .playing {
                Text("\(secondsRemaining)s")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(NestTheme.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(NestTheme.cardBackground)
                            .overlay(Capsule().strokeBorder(NestTheme.cardStroke, lineWidth: 1))
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .overlay(alignment: .trailing) {
            if let lastPopPoints, phase == .playing {
                Text("+\(lastPopPoints)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(NestTheme.accentGradient))
                    .opacity(popFlashOpacity)
                    .offset(x: -24, y: 36)
            }
        }
    }

    private var difficultyPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NestTheme.secondaryText)

            HStack(spacing: 10) {
                ForEach(BubbleDifficulty.allCases) { option in
                    Button {
                        difficulty = option
                    } label: {
                        VStack(spacing: 4) {
                            Text(option.title)
                                .font(.subheadline.weight(.semibold))
                            Text(option.subtitle)
                                .font(.caption2)
                                .opacity(0.8)
                        }
                        .foregroundStyle(
                            difficulty == option ? Color.white : NestTheme.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    difficulty == option
                                        ? Color.white.opacity(0.18)
                                        : Color.white.opacity(0.06)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(option.title) difficulty")
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(NestTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }

    private var finishedCard: some View {
        VStack(spacing: 10) {
            Text("Time’s up")
                .font(.title3.weight(.bold))
                .foregroundStyle(NestTheme.primaryText)
            Text("You scored \(softScore)")
                .font(.body)
                .foregroundStyle(NestTheme.secondaryText)
            Text(difficulty.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(NestTheme.secondaryText)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(NestTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                )
        )
        .padding(.horizontal, 36)
    }

    private func bubbleView(_ bubble: Bubble) -> some View {
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
    }

    /// Starts a timed round using the selected difficulty.
    private func startRound() {
        NestSoundPlayer.shared.play(.chime)
        softScore = 0
        secondsRemaining = 30
        bubbles = []
        lastPopPoints = nil
        phase = .playing
        startSpawning()
        startTimer()
    }

    /// Returns to the difficulty picker for another round.
    private func resetToReady() {
        stopRound()
        softScore = 0
        secondsRemaining = 30
        bubbles = []
        lastPopPoints = nil
        phase = .ready
    }

    /// Cancels active spawn and countdown work.
    private func stopRound() {
        spawnTask?.cancel()
        spawnTask = nil
        timerTask?.cancel()
        timerTask = nil
    }

    /// Counts down from 30 seconds, then ends the round.
    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled, secondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    secondsRemaining -= 1
                    if secondsRemaining <= 0 {
                        endRound()
                    }
                }
            }
        }
    }

    /// Stops spawning and shows the final score.
    private func endRound() {
        spawnTask?.cancel()
        spawnTask = nil
        timerTask?.cancel()
        timerTask = nil
        withAnimation(.easeOut(duration: 0.25)) {
            bubbles = []
            phase = .finished
        }
    }

    /// Begins spawning floating bubbles at the current difficulty pace.
    private func startSpawning() {
        spawnTask?.cancel()
        spawnTask = Task {
            while !Task.isCancelled {
                await MainActor.run { spawnBubble() }
                try? await Task.sleep(
                    for: .milliseconds(Int.random(in: difficulty.spawnIntervalMilliseconds))
                )
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
            opacity: 0.9,
            points: difficulty.pointsPerPop
        )
        bubbles.append(bubble)

        let riseDuration = Double.random(in: difficulty.riseDurationRange)
        withAnimation(.easeOut(duration: riseDuration)) {
            if let index = bubbles.firstIndex(where: { $0.id == bubble.id }) {
                bubbles[index].position.y = -80
                bubbles[index].opacity = 0.15
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + riseDuration + 0.4) {
            bubbles.removeAll { $0.id == bubble.id }
        }
    }

    /// Softly removes a tapped bubble and awards its points.
    private func pop(_ bubble: Bubble) {
        NestHaptics.softTap()
        NestSoundPlayer.shared.play(.softPop)
        softScore += bubble.points
        lastPopPoints = bubble.points
        popFlashOpacity = 1
        let burst = PopBurst(center: bubble.position)
        popBursts.append(burst)
        withAnimation(.easeOut(duration: 0.25)) {
            bubbles.removeAll { $0.id == bubble.id }
        }
        withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
            popFlashOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            popBursts.removeAll { $0.id == burst.id }
        }
    }
}

/// Rise speed and point value for a Bubble Drift round.
private enum BubbleDifficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var subtitle: String {
        switch self {
        case .easy: return "Slow rise"
        case .medium: return "Steady"
        case .hard: return "Fast rise"
        }
    }

    var riseDurationRange: ClosedRange<Double> {
        switch self {
        case .easy: return 5.5...8.5
        case .medium: return 3.2...5.0
        case .hard: return 1.8...3.0
        }
    }

    var spawnIntervalMilliseconds: ClosedRange<Int> {
        switch self {
        case .easy: return 700...1_400
        case .medium: return 450...900
        case .hard: return 280...560
        }
    }

    var pointsPerPop: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}

private struct Bubble: Identifiable {
    let id = UUID()
    var size: CGFloat
    var position: CGPoint
    var tint: Color
    var opacity: Double
    var points: Int
}

private struct PopBurst: Identifiable {
    let id = UUID()
    let center: CGPoint
}

#Preview {
    NavigationStack {
        BubbleDriftToolView()
    }
}
