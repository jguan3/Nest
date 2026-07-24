import SwiftUI

/// Immersive recording screen with a reactive gradient waveform.
struct RecordingScreenView: View {
    let amplitude: CGFloat
    let density: CGFloat
    let samples: [CGFloat]
    let partialTranscript: String
    let onStop: () -> Void

    @State private var glowPulse = false
    @State private var lastBlipAmplitude: CGFloat = 0

    var body: some View {
        ZStack {
            amplitudeGlow

            VStack(spacing: 0) {
                recordingHeader
                    .padding(.top, 20)
                    .padding(.horizontal, 28)

                Spacer()

                waveformStage
                    .padding(.horizontal, 20)

                if !recentWords.isEmpty {
                    transcriptPreview
                        .padding(.horizontal, 32)
                        .padding(.top, 28)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                StopRecordingButton(action: onStop)
                    .padding(.bottom, 52)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            NestSoundPlayer.shared.startListeningAmbience()
            NestSoundPlayer.shared.play(.listeningStart)
        }
        .onDisappear {
            NestSoundPlayer.shared.stopListeningAmbience()
        }
        .onChange(of: amplitude) { _, newAmplitude in
            guard newAmplitude > 0.42, newAmplitude - lastBlipAmplitude > 0.18 else { return }
            lastBlipAmplitude = newAmplitude
            NestSoundPlayer.shared.play(.listeningBlip)
        }
    }

    private var recordingHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(glowPulse ? 0.35 : 0.15))
                    .frame(width: 22, height: 22)
                    .blur(radius: 4)
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
            }

            Text("Listening")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NestTheme.primaryText.opacity(0.9))
                .tracking(0.6)

            Spacer()

            LiveBars(amplitude: amplitude)
        }
    }

    private var waveformStage: some View {
        RecordingWaveformView(
            amplitude: amplitude,
            density: density,
            samples: samples
        )
        .frame(height: 140)
        .frame(maxWidth: .infinity)
    }

    private var transcriptPreview: some View {
        Text(recentWords)
            .font(.title3.weight(.medium))
            .foregroundStyle(NestTheme.primaryText.opacity(0.92))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .animation(.easeOut(duration: 0.12), value: recentWords)
            .id(recentWords)
            .transition(.opacity)
    }

    /// Keeps only the latest few spoken words so the screen stays calm.
    private var recentWords: String {
        let words = partialTranscript
            .split { $0.isWhitespace || $0.isNewline }
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !words.isEmpty else { return "" }
        return words.suffix(5).joined(separator: " ")
    }

    private var amplitudeGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.72, green: 0.42, blue: 1.0).opacity(0.22 + amplitude * 0.28),
                        Color(red: 0.45, green: 0.55, blue: 1.0).opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 280
                )
            )
            .frame(width: 420, height: 420)
            .blur(radius: 30)
            .offset(y: -40)
            .animation(.easeOut(duration: 0.15), value: amplitude)
    }
}

private struct LiveBars: View {
    let amplitude: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.72, green: 0.50, blue: 1.0),
                                Color(red: 0.92, green: 0.40, blue: 0.65)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: barHeight(for: index))
                    .animation(.easeOut(duration: 0.12), value: amplitude)
            }
        }
        .frame(height: 18)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let stagger = CGFloat(index) * 0.08
        return 6 + (amplitude * 12) * (0.6 + stagger)
    }
}
