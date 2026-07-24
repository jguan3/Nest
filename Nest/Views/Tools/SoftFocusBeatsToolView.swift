import AVFoundation
import Combine
import SwiftUI

/// Calm-the-body tool that loops soft ADHD-friendly focus music.
struct SoftFocusBeatsToolView: View {
    @StateObject private var player = FocusLoopPlayer()
    @State private var pulse = false

    var body: some View {
        ZStack {
            NestBackground()
            ToolStageBackdrop(accent: Color(red: 0.55, green: 0.75, blue: 0.95))
                .offset(y: -10)

            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("Soft Focus Beats")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(NestTheme.primaryText)

                    Text(player.isPlaying ? "Let the loop hold your attention." : "A gentle loop for focus and settling.")
                        .font(.subheadline)
                        .foregroundStyle(NestTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.7, blue: 1.0).opacity(player.isPlaying ? 0.35 : 0.16),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 140
                            )
                        )
                        .frame(width: 260, height: 260)
                        .scaleEffect(pulse && player.isPlaying ? 1.06 : 1)

                    Image(systemName: "waveform")
                        .font(.system(size: 54, weight: .medium))
                        .foregroundStyle(NestTheme.primaryText.opacity(0.9))
                        .symbolEffect(.variableColor.iterative, isActive: player.isPlaying)
                }
                .frame(height: 280)

                if let errorMessage = player.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(Color.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                Button {
                    player.toggle()
                    if player.isPlaying {
                        NestHaptics.softTap()
                    }
                } label: {
                    Text(player.isPlaying ? "Pause" : "Play")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: 200)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(NestTheme.accentGradient))
                }
                .buttonStyle(.plain)

                Text("Loops quietly in the background of this screen.")
                    .font(.footnote)
                    .foregroundStyle(NestTheme.secondaryText)
                    .padding(.bottom, 24)
            }
        }
        .navigationTitle("Soft Focus Beats")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
            player.prepare()
        }
        .onDisappear {
            player.stop()
        }
    }
}

/// Loops the bundled ADHD focus audio track.
@MainActor
final class FocusLoopPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var errorMessage: String?

    private var audioPlayer: AVAudioPlayer?

    /// Loads the bundled focus loop if needed.
    func prepare() {
        guard audioPlayer == nil else { return }
        guard let url = Bundle.main.url(forResource: "ADHDFocusLoop", withExtension: "m4a") else {
            errorMessage = "Focus loop audio is missing from the app bundle."
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.prepareToPlay()
            audioPlayer = player
            errorMessage = nil
        } catch {
            errorMessage = "Couldn’t load the focus loop."
            print("FocusLoopPlayer: \(error.localizedDescription)")
        }
    }

    /// Toggles looping playback.
    func toggle() {
        prepare()
        guard let audioPlayer else { return }
        if audioPlayer.isPlaying {
            audioPlayer.pause()
            isPlaying = false
        } else {
            audioPlayer.play()
            isPlaying = true
            NestSoundPlayer.shared.play(.chime)
        }
    }

    /// Stops playback when leaving the tool.
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
    }
}

#Preview {
    NavigationStack {
        SoftFocusBeatsToolView()
    }
}
