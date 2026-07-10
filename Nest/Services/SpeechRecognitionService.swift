import AVFoundation
import Combine
import Speech

/// Result returned when a capture session ends.
struct CaptureResult {
    let transcript: String
    let audioFileName: String?
    let duration: TimeInterval
}

/// Manages live speech-to-text capture and parallel voice memo recording.
@MainActor
final class SpeechRecognitionService: ObservableObject {
    @Published private(set) var partialTranscript = ""
    @Published private(set) var isListening = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var waveformSamples: [CGFloat] = []
    @Published private(set) var speechDensity: CGFloat = 0
    @Published private(set) var currentAmplitude: CGFloat = 0

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private var recordingStartedAt: Date?
    private var latestTranscript = ""
    private var receivedFinalTranscript = false
    private var lastTranscriptLength = 0
    private var lastTranscriptUpdate = Date()
    private let maxWaveformSamples = 120

    /// Requests microphone and speech permissions lazily on first use.
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

        tearDownAudioCapture(cancelRecognition: true)
        partialTranscript = ""
        latestTranscript = ""
        waveformSamples = []
        speechDensity = 0
        currentAmplitude = 0
        receivedFinalTranscript = false
        lastTranscriptLength = 0
        lastTranscriptUpdate = Date()
        errorMessage = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        if #available(iOS 13.0, *) {
            request.requiresOnDeviceRecognition = false
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let busFormat = inputNode.outputFormat(forBus: 0)
        let sampleRate = busFormat.sampleRate > 0 ? busFormat.sampleRate : 44_100

        guard let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw SpeechError.audioSetupFailed
        }

        let fileURL = AudioFileStore.makeRecordingURL()
        recordingURL = fileURL
        audioFile = try AVAudioFile(forWriting: fileURL, settings: recordingFormat.settings)
        recordingStartedAt = Date()

        let converter = AVAudioConverter(from: busFormat, to: recordingFormat)
        let writingFile = audioFile

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: busFormat) { buffer, _ in
            request.append(buffer)
            Self.writeBuffer(buffer, converter: converter, to: writingFile)
            Self.publishLevel(from: buffer) { [weak self] level in
                Task { @MainActor in
                    self?.currentAmplitude = level
                    self?.appendWaveformSample(level)
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    self.updateTranscript(result.bestTranscription.formattedString)
                    if result.isFinal {
                        self.receivedFinalTranscript = true
                    }
                }

                if let error, !self.isCancellationError(error) {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// Stops listening and returns the capture result.
    func stopListening() async -> CaptureResult {
        recognitionRequest?.endAudio()

        let deadline = Date().addingTimeInterval(2.0)
        while !receivedFinalTranscript && Date() < deadline {
            try? await Task.sleep(for: .milliseconds(50))
        }

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        let duration: TimeInterval
        if let recordingStartedAt {
            duration = Date().timeIntervalSince(recordingStartedAt)
        } else {
            duration = 0
        }

        audioFile = nil

        var savedFileName: String?
        var savedURL: URL?
        if let recordingURL, FileManager.default.fileExists(atPath: recordingURL.path) {
            let attributes = try? FileManager.default.attributesOfItem(atPath: recordingURL.path)
            let fileSize = attributes?[.size] as? Int ?? 0
            if fileSize > 500, duration > 0.2 {
                savedFileName = recordingURL.lastPathComponent
                savedURL = recordingURL
            } else {
                try? FileManager.default.removeItem(at: recordingURL)
            }
        }

        tearDownAudioCapture(cancelRecognition: true)

        var finalText = latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        if let savedURL {
            let fileTranscript = await TranscriptionService.transcribeAudio(at: savedURL)
            if fileTranscript.count >= finalText.count {
                finalText = fileTranscript
            }
        }

        partialTranscript = finalText
        recordingStartedAt = nil
        recordingURL = nil

        return CaptureResult(
            transcript: finalText,
            audioFileName: savedFileName,
            duration: duration
        )
    }

    private func tearDownAudioCapture(cancelRecognition: Bool) {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        audioEngine.reset()

        if cancelRecognition {
            recognitionTask?.cancel()
            recognitionTask = nil
            recognitionRequest = nil
        }

        isListening = false
        speechDensity = 0
    }

    private static func writeBuffer(
        _ buffer: AVAudioPCMBuffer,
        converter: AVAudioConverter?,
        to file: AVAudioFile?
    ) {
        guard let file else { return }

        if let converter {
            let capacity = AVAudioFrameCount(
                Double(buffer.frameLength) * converter.outputFormat.sampleRate / max(converter.inputFormat.sampleRate, 1)
            ) + 1
            guard let converted = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: capacity) else {
                return
            }

            var consumed = false
            var conversionError: NSError?
            converter.convert(to: converted, error: &conversionError) { _, status in
                if consumed {
                    status.pointee = .noDataNow
                    return nil
                }
                consumed = true
                status.pointee = .haveData
                return buffer
            }

            if conversionError == nil, converted.frameLength > 0 {
                try? file.write(from: converted)
            }
        } else {
            try? file.write(from: buffer)
        }
    }

    private static func publishLevel(from buffer: AVAudioPCMBuffer, handler: @escaping (CGFloat) -> Void) {
        handler(normalizedLevel(from: buffer))
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

    private func appendWaveformSample(_ level: CGFloat) {
        let smoothed = max(level, waveformSamples.last.map { $0 * 0.82 } ?? 0)
        waveformSamples.append(smoothed)
        if waveformSamples.count > maxWaveformSamples {
            waveformSamples.removeFirst(waveformSamples.count - maxWaveformSamples)
        }
    }

    private func isCancellationError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216
    }

    private static func normalizedLevel(from buffer: AVAudioPCMBuffer) -> CGFloat {
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
        case audioSetupFailed

        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable:
                "Speech recognition is not available."
            case .audioSetupFailed:
                "Could not set up audio recording."
            }
        }
    }
}
