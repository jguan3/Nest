import AVFoundation
import Combine

/// Plays back saved voice memo audio files.
@MainActor
final class VoiceMemoPlayer: ObservableObject {
    @Published private(set) var playingThoughtID: UUID?
    @Published private(set) var isPlaying = false

    private var player: AVAudioPlayer?

    /// Toggles playback for a thought's voice memo.
    /// - Parameter thought: The thought whose audio should play or stop.
    func togglePlayback(for thought: Thought) {
        if playingThoughtID == thought.id, isPlaying {
            stop()
            return
        }

        guard let fileName = thought.audioFileName else { return }
        let url = AudioFileStore.url(for: fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        stop()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            player = audioPlayer
            playingThoughtID = thought.id
            isPlaying = true

            let thoughtID = thought.id
            DispatchQueue.main.asyncAfter(deadline: .now() + audioPlayer.duration + 0.1) { [weak self] in
                guard self?.playingThoughtID == thoughtID else { return }
                self?.stop()
            }
        } catch {
            stop()
        }
    }

    /// Stops any active playback.
    func stop() {
        player?.stop()
        player = nil
        playingThoughtID = nil
        isPlaying = false
    }
}
