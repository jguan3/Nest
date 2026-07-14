import Combine
import SwiftData
import SwiftUI
import UIKit

/// Capture states for the primary recording flow.
enum CaptureState: Equatable {
    case idle
    case listening
    case processing
    case reflecting(ReflectionAnalysis)
    case crisis
    case saved
    case error
}

/// Coordinates speech capture, AI reflection, and persistence.
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
    @Published var pendingToolNavigation: CopingTool?

    private let speechService = SpeechRecognitionService()
    private let reflectionService: ReflectionAnalysisService
    private var observationTask: Task<Void, Never>?

    init(reflectionService: ReflectionAnalysisService = ReflectionAnalysisService()) {
        self.reflectionService = reflectionService
    }

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

    /// Ends capture, analyzes the transcript, and saves the thought with reflection.
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

        let transcript = result.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let analysis: ReflectionAnalysis

        do {
            analysis = try await reflectionService.analyze(
                transcript: transcript,
                availableFolders: folders
            )
        } catch {
            analysis = ReflectionAnalysisService.fallback()
        }

        let destinationFolder = FolderSuggestionResolver.resolve(
            suggestedFolder: analysis.suggestedFolder,
            folders: folders
        )

        let displayText: String
        if transcript.isEmpty {
            displayText = result.audioFileName != nil ? "Voice memo" : destinationFolder.name
        } else {
            displayText = transcript
        }

        let thought = Thought(
            text: displayText,
            fullTranscript: transcript.isEmpty ? nil : transcript,
            audioFileName: result.audioFileName,
            duration: result.duration,
            reflection: analysis.crisis ? nil : analysis.reflection,
            stressor: analysis.crisis ? nil : analysis.stressor,
            emotion: analysis.crisis ? nil : analysis.emotion,
            recommendedToolRaw: analysis.crisis ? nil : analysis.recommendedTool.rawValue,
            isCrisis: analysis.crisis,
            folder: destinationFolder
        )
        destinationFolder.thoughts.append(thought)
        modelContext.insert(thought)

        do {
            try modelContext.save()
            UserDefaults.standard.set(destinationFolder.name, forKey: "lastUsedFolderName")
            savedFolderName = destinationFolder.name
            savedFolderColorName = destinationFolder.colorName
            partialTranscript = ""

            if analysis.crisis {
                captureState = .crisis
            } else {
                captureState = .reflecting(analysis)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }

        } catch {
            captureState = .error
            errorMessage = "Could not save your thought."
        }
    }

    func dismissReflection() {
        captureState = .idle
    }

    func dismissCrisis() {
        captureState = .idle
    }

    func requestToolNavigation(_ tool: CopingTool) {
        pendingToolNavigation = tool
        captureState = .idle
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
