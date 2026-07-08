import AVFoundation
import Combine
import Speech

/// Manages live speech-to-text capture using Apple's Speech framework.
@MainActor
final class SpeechRecognitionService: ObservableObject {
    @Published private(set) var partialTranscript = ""
    @Published private(set) var isListening = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var waveformSamples: [CGFloat] = []
    @Published private(set) var speechDensity: CGFloat = 0

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var latestTranscript = ""
    private var lastTranscriptLength = 0
    private var lastTranscriptUpdate = Date()
    private let maxWaveformSamples = 72

    /// Requests microphone and speech permissions lazily on first use.
    /// - Returns: Whether both permissions were granted.
    func requestPermissions() async -> Bool {
        let speechGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechGranted else {
            errorMessage = "Speech recognition permission is required."
            return false
        }

        let micGranted: Bool
        if #available(iOS 17.0, macOS 14.0, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        if !micGranted {
            errorMessage = "Microphone permission is required."
        }
        return micGranted
    }

    /// Starts listening and publishing partial transcripts.
    func startListening() async throws {
        guard !isListening else { return }

        if speechRecognizer?.isAvailable != true {
            errorMessage = "Speech recognition is not available right now."
            throw SpeechError.recognizerUnavailable
        }

        stopListening()
        partialTranscript = ""
        latestTranscript = ""
        waveformSamples = []
        speechDensity = 0
        lastTranscriptLength = 0
        lastTranscriptUpdate = Date()
        errorMessage = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if #available(iOS 13.0, *) {
            request.requiresOnDeviceRecognition = speechRecognizer?.supportsOnDeviceRecognition ?? false
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 512, format: recordingFormat) { [weak self] buffer, _ in
            request.append(buffer)
            self?.processAudioBuffer(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    self.updateTranscript(result.bestTranscription.formattedString)
                }

                if let error {
                    self.errorMessage = error.localizedDescription
                    self.stopListening()
                }
            }
        }
    }

    /// Stops listening and returns the final transcript.
    /// - Returns: The best available transcript text.
    @discardableResult
    func stopListening() -> String {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        speechDensity = 0

        let finalText = latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        partialTranscript = finalText
        return finalText
    }

    private func updateTranscript(_ transcript: String) {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastTranscriptUpdate)
        let growth = transcript.count - lastTranscriptLength

        if elapsed > 0.08, growth > 0 {
            let charactersPerSecond = Double(growth) / elapsed
            let targetDensity = min(1, max(0, charactersPerSecond / 14))
            speechDensity = speechDensity * 0.55 + CGFloat(targetDensity) * 0.45
            lastTranscriptUpdate = now
            lastTranscriptLength = transcript.count
        } else if elapsed > 0.6 {
            speechDensity = max(0, speechDensity - 0.08)
            lastTranscriptUpdate = now
        }

        latestTranscript = transcript
        partialTranscript = transcript
    }

    private nonisolated func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        let level = Self.normalizedLevel(from: buffer)
        Task { @MainActor [weak self] in
            self?.appendWaveformSample(level)
        }
    }

    private func appendWaveformSample(_ level: CGFloat) {
        let smoothed = max(level, waveformSamples.last.map { $0 * 0.82 } ?? 0)
        waveformSamples.append(smoothed)
        if waveformSamples.count > maxWaveformSamples {
            waveformSamples.removeFirst(waveformSamples.count - maxWaveformSamples)
        }
    }

    private nonisolated static func normalizedLevel(from buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        var sum: Float = 0
        for index in 0..<frameLength {
            let sample = channelData[index]
            sum += sample * sample
        }

        let rootMeanSquare = sqrt(sum / Float(frameLength))
        let decibels = 20 * log10(max(rootMeanSquare, 0.000_01))
        let normalized = (decibels + 50) / 42
        return CGFloat(min(1, max(0.04, normalized)))
    }

    enum SpeechError: LocalizedError {
        case recognizerUnavailable

        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable:
                "Speech recognition is not available."
            }
        }
    }
}
