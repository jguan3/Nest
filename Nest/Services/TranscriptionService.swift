import Foundation
import NaturalLanguage
import Speech

/// Uses Apple Speech + language analysis to transcribe audio and detect folder intent.
enum TranscriptionService {
    /// Transcribes a local audio file using Apple's speech recognition (cloud when available).
    /// - Parameter url: Local audio file URL.
    /// - Returns: Transcribed text, or empty string on failure.
    static func transcribeAudio(at url: URL) async -> String {
        let authorized = await requestSpeechAuthorization()
        guard authorized else { return "" }

        return await withCheckedContinuation { continuation in
            guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
                  recognizer.isAvailable else {
                continuation.resume(returning: "")
                return
            }

            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            request.taskHint = .dictation
            if #available(iOS 13.0, *) {
                request.requiresOnDeviceRecognition = false
            }

            var bestText = ""
            var resumed = false

            let task = recognizer.recognitionTask(with: request) { result, error in
                if let result {
                    bestText = result.bestTranscription.formattedString
                    if result.isFinal, !resumed {
                        resumed = true
                        continuation.resume(returning: bestText)
                    }
                } else if let error, !isCancellation(error), !resumed {
                    resumed = true
                    continuation.resume(returning: bestText)
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                guard !resumed else { return }
                resumed = true
                task.cancel()
                continuation.resume(returning: bestText)
            }
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216
    }

    private static func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
