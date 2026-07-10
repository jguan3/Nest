import SwiftUI

/// Short guided body check-ins for releasing tension.
struct SoftUnwindToolView: View {
    @State private var stepIndex = 0
    @State private var isRunning = false
    @State private var glow = false
    @State private var cycleTask: Task<Void, Never>?

    private let steps = SoftUnwindStep.all

    var body: some View {
        ZStack {
            NestBackground()
            ToolStageBackdrop(accent: Color(red: 0.45, green: 0.75, blue: 0.65))

            VStack(spacing: 24) {
                Text(isRunning ? "Soft Unwind" : "A gentle body check-in")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(NestTheme.primaryText)

                ZStack {
                    Circle()
                        .fill(steps[stepIndex].tint.opacity(glow ? 0.28 : 0.14))
                        .frame(width: 250, height: 250)
                        .blur(radius: 20)

                    Circle()
                        .fill(NestTheme.cardBackground)
                        .frame(width: 210, height: 210)
                        .overlay(Circle().strokeBorder(NestTheme.cardStroke, lineWidth: 1))

                    VStack(spacing: 14) {
                        Image(systemName: steps[stepIndex].symbol)
                            .font(.system(size: 44))
                            .foregroundStyle(steps[stepIndex].tint)
                        Text(steps[stepIndex].title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(NestTheme.primaryText)
                    }
                    .animation(.easeInOut(duration: 0.35), value: stepIndex)
                }

                Text(steps[stepIndex].prompt)
                    .font(.body)
                    .foregroundStyle(NestTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .frame(minHeight: 60)
                    .animation(.easeInOut(duration: 0.35), value: stepIndex)

                // Step dots
                HStack(spacing: 8) {
                    ForEach(steps.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == stepIndex ? Color.white.opacity(0.85) : Color.white.opacity(0.2))
                            .frame(width: index == stepIndex ? 18 : 8, height: 8)
                    }
                }

                Button {
                    if isRunning { stop() } else { start() }
                } label: {
                    Text(isRunning ? "Stop" : "Begin")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: 200)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(NestTheme.accentGradient))
                }
                .buttonStyle(.plain)

                if isRunning {
                    Text("Step \(stepIndex + 1) of \(steps.count)")
                        .font(.caption)
                        .foregroundStyle(NestTheme.secondaryText)
                }
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Soft Unwind")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
        .onDisappear { stop() }
    }

    /// Starts cycling through unwind steps.
    private func start() {
        isRunning = true
        stepIndex = 0
        cycleTask?.cancel()
        cycleTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(8))
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    if stepIndex < steps.count - 1 {
                        stepIndex += 1
                    } else {
                        stop()
                    }
                }
            }
        }
    }

    /// Stops the unwind session.
    private func stop() {
        cycleTask?.cancel()
        cycleTask = nil
        isRunning = false
        stepIndex = 0
    }
}

private struct SoftUnwindStep {
    let title: String
    let prompt: String
    let symbol: String
    let tint: Color

    static let all: [SoftUnwindStep] = [
        SoftUnwindStep(title: "Jaw", prompt: "Unclench your jaw. Let your tongue rest softly.", symbol: "mouth", tint: Color(red: 1.0, green: 0.7, blue: 0.55)),
        SoftUnwindStep(title: "Shoulders", prompt: "Drop your shoulders away from your ears.", symbol: "figure.stand", tint: Color(red: 0.65, green: 0.75, blue: 1.0)),
        SoftUnwindStep(title: "Hands", prompt: "Open your hands. Feel the air on your palms.", symbol: "hand.raised", tint: Color(red: 0.95, green: 0.65, blue: 0.85)),
        SoftUnwindStep(title: "Belly", prompt: "Let your belly soften. No need to hold it in.", symbol: "leaf", tint: Color(red: 0.55, green: 0.85, blue: 0.65)),
        SoftUnwindStep(title: "Feet", prompt: "Press your feet into the floor. You’re here.", symbol: "shoeprints.fill", tint: Color(red: 0.85, green: 0.7, blue: 0.45)),
        SoftUnwindStep(title: "Breath", prompt: "Take one slower breath out than in.", symbol: "wind", tint: Color(red: 0.55, green: 0.8, blue: 0.95))
    ]
}

#Preview {
    NavigationStack {
        SoftUnwindToolView()
    }
}
