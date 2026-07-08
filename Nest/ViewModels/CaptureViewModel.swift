import Combine
import SwiftData
import SwiftUI
import UIKit

/// Capture states for the primary recording flow.
enum CaptureState: Equatable {
    case idle
    case listening
    case processing
    case saved
    case error
}

/// Coordinates speech capture, keyword routing, and persistence.
@MainActor
final class CaptureViewModel: ObservableObject {
    @Published private(set) var captureState: CaptureState = .idle
    @Published private(set) var partialTranscript = ""
    @Published private(set) var waveformSamples: [CGFloat] = []
    @Published private(set) var speechDensity: CGFloat = 0
    @Published private(set) var savedFolderName: String?
    @Published private(set) var savedFolderColorName: String?
    @Published private(set) var errorMessage: String?

    private let speechService = SpeechRecognitionService()
    private var saveResetTask: Task<Void, Never>?
    private var observationTask: Task<Void, Never>?

    /// Begins a new voice capture session.
    func startRecording() async {
        guard captureState != .listening, captureState != .processing else { return }

        let granted = await speechService.requestPermissions()
        guard granted else {
            captureState = .error
            errorMessage = speechService.errorMessage
            return
        }

        do {
            try await speechService.startListening()
            captureState = .listening
            errorMessage = nil
            beginObservingSpeechService()
        } catch {
            captureState = .error
            errorMessage = error.localizedDescription
        }
    }

    /// Ends capture and saves the routed thought.
    /// - Parameters:
    ///   - folders: Available folders for keyword routing.
    ///   - modelContext: SwiftData context for persistence.
    func stopRecording(folders: [ThoughtFolder], modelContext: ModelContext) async {
        guard captureState == .listening else { return }

        captureState = .processing
        observationTask?.cancel()
        let transcript = speechService.stopListening()
        partialTranscript = transcript
        waveformSamples = []
        speechDensity = 0

        guard !transcript.isEmpty else {
            captureState = .idle
            partialTranscript = ""
            return
        }

        let route = FolderRouter.route(transcript: transcript, folders: folders)
        let thought = Thought(text: route.cleanedText, folder: route.folder)
        modelContext.insert(thought)

        do {
            try modelContext.save()
            UserDefaults.standard.set(route.folder.name, forKey: "lastUsedFolderName")
            triggerSavedFeedback(folder: route.folder)
        } catch {
            captureState = .error
            errorMessage = "Could not save your thought."
        }
    }

    private func beginObservingSpeechService() {
        observationTask?.cancel()
        observationTask = Task {
            while !Task.isCancelled, speechService.isListening {
                partialTranscript = speechService.partialTranscript
                waveformSamples = speechService.waveformSamples
                speechDensity = speechService.speechDensity
                try? await Task.sleep(for: .milliseconds(30))
            }

            partialTranscript = speechService.partialTranscript
            waveformSamples = speechService.waveformSamples
            speechDensity = speechService.speechDensity
        }
    }

    private func triggerSavedFeedback(folder: ThoughtFolder) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        savedFolderName = folder.name
        savedFolderColorName = folder.colorName
        captureState = .saved

        saveResetTask?.cancel()
        saveResetTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            captureState = .idle
            partialTranscript = ""
            waveformSamples = []
            speechDensity = 0
            savedFolderName = nil
            savedFolderColorName = nil
        }
    }
}
