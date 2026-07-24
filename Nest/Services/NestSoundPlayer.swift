import AVFoundation
import Foundation

/// Soft synthesized sound cues for Nest interactions (no bundled audio files).
enum NestSoundEffect {
    case chirp
    case softPop
    case ripple
    case breathIn
    case breathOut
    case seal
    case release
    case chime
    case sparkle
    case sleep
    case listeningStart
    case listeningBlip
}

/// Plays short in-memory tones for calm tool and bird feedback.
@MainActor
final class NestSoundPlayer {
    static let shared = NestSoundPlayer()

    private var player: AVAudioPlayer?
    private var blipPlayer: AVAudioPlayer?
    private var ambiencePlayer: AVAudioPlayer?

    private init() {}

    /// Plays a named soft effect, replacing any currently playing one-shot cue.
    /// - Parameter effect: The sound to play.
    func play(_ effect: NestSoundEffect) {
        let soundsEnabled = UserDefaults.standard.object(forKey: NestSettingsKeys.soundsEnabled) as? Bool ?? true
        guard soundsEnabled else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            // Prefer mixing so recording ambience / speech recognition can keep the mic.
            try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let data = try Self.makeWave(for: effect)
            let audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.prepareToPlay()
            audioPlayer.volume = effect.volume

            if effect == .listeningBlip {
                blipPlayer = audioPlayer
            } else {
                player = audioPlayer
            }
            audioPlayer.play()
        } catch {
            print("NestSoundPlayer: could not play \(effect) — \(error.localizedDescription)")
        }
    }

    /// Starts a quiet looping pad behind the recording UI.
    func startListeningAmbience() {
        let soundsEnabled = UserDefaults.standard.object(forKey: NestSettingsKeys.soundsEnabled) as? Bool ?? true
        guard soundsEnabled else { return }
        guard ambiencePlayer == nil || ambiencePlayer?.isPlaying == false else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.mixWithOthers, .defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
            let data = try Self.makeListeningAmbienceWave()
            let audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.numberOfLoops = -1
            audioPlayer.volume = 0.18
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            ambiencePlayer = audioPlayer
        } catch {
            print("NestSoundPlayer: could not start listening ambience — \(error.localizedDescription)")
        }
    }

    /// Stops the recording ambience loop.
    func stopListeningAmbience() {
        ambiencePlayer?.stop()
        ambiencePlayer = nil
    }

    private static func makeWave(for effect: NestSoundEffect) throws -> Data {
        let sampleRate = 22_050.0
        let duration = effect.duration
        let sampleCount = Int(sampleRate * duration)
        var samples = [Int16](repeating: 0, count: sampleCount)

        for index in 0..<sampleCount {
            let time = Double(index) / sampleRate
            let envelope = fadeEnvelope(time: time, duration: duration)
            let sample = effect.sample(at: time) * envelope
            let clamped = max(-1, min(1, sample))
            samples[index] = Int16(clamped * Double(Int16.max) * 0.55)
        }

        return try wavData(samples: samples, sampleRate: Int(sampleRate))
    }

    private static func makeListeningAmbienceWave() throws -> Data {
        let sampleRate = 22_050.0
        let duration = 2.4
        let sampleCount = Int(sampleRate * duration)
        var samples = [Int16](repeating: 0, count: sampleCount)

        for index in 0..<sampleCount {
            let time = Double(index) / sampleRate
            let slow = sin(2 * .pi * 110 * time) * 0.35
            let mid = sin(2 * .pi * 164 * time) * 0.18
            let shimmer = sin(2 * .pi * 330 * time) * 0.06
            let breath = sin(2 * .pi * 0.45 * time) * 0.25 + 0.75
            let sample = (slow + mid + shimmer) * breath
            let clamped = max(-1, min(1, sample))
            samples[index] = Int16(clamped * Double(Int16.max) * 0.4)
        }

        return try wavData(samples: samples, sampleRate: Int(sampleRate))
    }

    private static func fadeEnvelope(time: Double, duration: Double) -> Double {
        let attack = min(0.02, duration * 0.2)
        let release = min(0.08, duration * 0.45)
        if time < attack { return time / attack }
        if time > duration - release { return max(0, (duration - time) / release) }
        return 1
    }

    private static func wavData(samples: [Int16], sampleRate: Int) throws -> Data {
        let dataSize = samples.count * 2
        var data = Data()

        func appendASCII(_ string: String) {
            data.append(contentsOf: string.utf8)
        }
        func appendUInt16(_ value: UInt16) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        func appendUInt32(_ value: UInt32) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }

        appendASCII("RIFF")
        appendUInt32(UInt32(36 + dataSize))
        appendASCII("WAVE")
        appendASCII("fmt ")
        appendUInt32(16)
        appendUInt16(1)
        appendUInt16(1)
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(sampleRate * 2))
        appendUInt16(2)
        appendUInt16(16)
        appendASCII("data")
        appendUInt32(UInt32(dataSize))

        for sample in samples {
            var little = sample.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        return data
    }
}

private extension NestSoundEffect {
    var duration: Double {
        switch self {
        case .chirp: return 0.18
        case .softPop: return 0.12
        case .ripple: return 0.35
        case .breathIn: return 0.28
        case .breathOut: return 0.32
        case .seal: return 0.22
        case .release: return 0.4
        case .chime: return 0.45
        case .sparkle: return 0.2
        case .sleep: return 0.3
        case .listeningStart: return 0.32
        case .listeningBlip: return 0.08
        }
    }

    var volume: Float {
        switch self {
        case .breathIn, .breathOut, .sleep: return 0.35
        case .ripple, .release: return 0.4
        case .listeningStart: return 0.28
        case .listeningBlip: return 0.16
        default: return 0.45
        }
    }

    func sample(at time: Double) -> Double {
        switch self {
        case .chirp:
            let frequency = 880 + time * 420
            return sin(2 * .pi * frequency * time)
        case .softPop:
            let frequency = 520 - time * 180
            return sin(2 * .pi * frequency * time) * (1 - time * 4)
        case .ripple:
            return sin(2 * .pi * 340 * time) * 0.7
                + sin(2 * .pi * 510 * time) * 0.3
        case .breathIn:
            return sin(2 * .pi * 220 * time) * 0.5
                + sin(2 * .pi * 330 * time) * 0.2
        case .breathOut:
            return sin(2 * .pi * 180 * time) * 0.45
                + sin(2 * .pi * 270 * time) * 0.2
        case .seal:
            return sin(2 * .pi * 420 * time) + sin(2 * .pi * 630 * time) * 0.35
        case .release:
            let frequency = 360 + time * 180
            return sin(2 * .pi * frequency * time) * 0.8
        case .chime:
            return sin(2 * .pi * 660 * time) * 0.7
                + sin(2 * .pi * 990 * time) * 0.35
        case .sparkle:
            return sin(2 * .pi * 1200 * time) * 0.55
                + sin(2 * .pi * 1600 * time) * 0.25
        case .sleep:
            return sin(2 * .pi * 260 * time) * 0.4
                + sin(2 * .pi * 195 * time) * 0.3
        case .listeningStart:
            return sin(2 * .pi * 480 * time) * 0.55
                + sin(2 * .pi * 720 * time) * 0.25
        case .listeningBlip:
            let frequency = 760 + time * 220
            return sin(2 * .pi * frequency * time) * (1 - time * 8)
        }
    }
}
