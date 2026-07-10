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
    @Published private(set) var currentAmplitude: CGFloat = 0
    @Published private(set) var savedFolderName: String?
    @Published private(set) var savedFolderColorName: String?
    @Published private(set) var errorMessage: String?
    @Published var folderToOpen: ThoughtFolder?

    private let speechService = SpeechRecognitionService()
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
            folderToOpen = nil
            beginObservingSpeechService()
        } catch {
            captureState = .error
            errorMessage = error.localizedDescription
        }
    }

    /// Ends capture and saves the routed thought with voice memo.
    func stopRecording(folders: [ThoughtFolder], modelContext: ModelContext) async {
        guard captureState == .listening else { return }

        captureState = .processing
        observationTask?.cancel()

        let result = await speechService.stopListening()
        partialTranscript = result.transcript
        waveformSamples = []
        speechDensity = 0
        currentAmplitude = 0

        guard !result.transcript.isEmpty || result.audioFileName != nil else {
            captureState = .error
            errorMessage = "Nothing was captured. Try speaking again."
            return
        }

        let route = FolderRouter.route(transcript: result.transcript, folders: folders)
        let displayText: String
        if route.cleanedText.isEmpty {
            displayText = result.audioFileName != nil ? "Voice memo" : route.folder.name
        } else {
            displayText = route.cleanedText
        }

        let thought = Thought(
            text: displayText,
            fullTranscript: result.transcript.isEmpty ? nil : result.transcript,
            audioFileName: result.audioFileName,
            duration: result.duration,
            folder: route.folder
        )
        route.folder.thoughts.append(thought)
        modelContext.insert(thought)

        do {
            try modelContext.save()
            UserDefaults.standard.set(route.folder.name, forKey: "lastUsedFolderName")
            savedFolderName = route.folder.name
            savedFolderColorName = route.folder.colorName
            folderToOpen = route.folder
            captureState = .idle
            partialTranscript = ""

            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
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
                currentAmplitude = speechService.currentAmplitude
                try? await Task.sleep(for: .milliseconds(30))
            }

            partialTranscript = speechService.partialTranscript
            waveformSamples = speechService.waveformSamples
            speechDensity = speechService.speechDensity
            currentAmplitude = speechService.currentAmplitude
        }
    }
}
