import SwiftUI

/// A quiet focus timer for holding attention on one task.
struct FocusToolView: View {
    @State private var selectedMinutes = 5
    @State private var remainingSeconds = 0
    @State private var isRunning = false
    @State private var timerTask: Task<Void, Never>?
    @State private var pulse = false
    @State private var orbit = false

    private let minuteOptions = [2, 5, 10, 15]

    var body: some View {
        ZStack {
            NestBackground()
            ToolStageBackdrop(accent: Color(red: 0.55, green: 0.45, blue: 0.95))

            VStack(spacing: 26) {
                VStack(spacing: 8) {
                    Text(isRunning ? "Stay with this one thing." : "Pick a short focus window.")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(NestTheme.primaryText)
                        .multilineTextAlignment(.center)

                    Text(isRunning ? "The bubble holds the time for you." : "Short windows are easier to keep.")
                        .font(.subheadline)
                        .foregroundStyle(NestTheme.secondaryText)
                }
                .padding(.horizontal, 28)

                ZStack {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 6, height: 6)
                            .offset(y: -128)
                            .rotationEffect(.degrees(Double(index) * 60 + (orbit ? 20 : 0)))
                    }

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.55, green: 0.5, blue: 1.0).opacity(isRunning ? 0.35 : 0.18),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 140
                            )
                        )
                        .frame(width: 260, height: 260)
                        .scaleEffect(pulse && isRunning ? 1.05 : 1)

                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 12)
                        .frame(width: 220, height: 220)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            NestTheme.accentGradient,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.9), value: remainingSeconds)

                    VStack(spacing: 4) {
                        Text(timeLabel)
                            .font(.system(size: 46, weight: .semibold, design: .rounded))
                            .foregroundStyle(NestTheme.primaryText)
                        Text(isRunning ? "remaining" : "ready")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(NestTheme.secondaryText)
                    }
                }

                if !isRunning {
                    HStack(spacing: 10) {
                        ForEach(minuteOptions, id: \.self) { minutes in
                            Button {
                                selectedMinutes = minutes
                            } label: {
                                Text("\(minutes)m")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(selectedMinutes == minutes ? Color.white : NestTheme.secondaryText)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(selectedMinutes == minutes ? Color.white.opacity(0.18) : NestTheme.cardBackground)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    Text("One task. Soft edges. You’re doing enough.")
                        .font(.footnote)
                        .foregroundStyle(NestTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }

                Button {
                    if isRunning { stopFocus() } else { startFocus() }
                } label: {
                    Text(isRunning ? "End early" : "Start focus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: 220)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(NestTheme.accentGradient))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Focus Bubble")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                orbit = true
            }
        }
        .onDisappear { stopFocus() }
    }

    private var totalSeconds: Int { selectedMinutes * 60 }

    private var progress: CGFloat {
        guard totalSeconds > 0, isRunning || remainingSeconds > 0 else { return 0 }
        return CGFloat(remainingSeconds) / CGFloat(totalSeconds)
    }

    private var timeLabel: String {
        let seconds = isRunning || remainingSeconds > 0 ? remainingSeconds : totalSeconds
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    /// Starts the focus countdown.
    private func startFocus() {
        remainingSeconds = totalSeconds
        isRunning = true
        pulse = true
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled, remainingSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                remainingSeconds -= 1
            }
            if remainingSeconds == 0 {
                await MainActor.run {
                    isRunning = false
                    pulse = false
                }
            }
        }
    }

    /// Ends the focus session early.
    private func stopFocus() {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
        pulse = false
        remainingSeconds = 0
    }
}

#Preview {
    NavigationStack {
        FocusToolView()
    }
}
