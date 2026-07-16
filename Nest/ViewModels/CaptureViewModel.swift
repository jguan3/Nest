import Combine
import SwiftData
import SwiftUI
import UIKit

/// Why the capture flow is in a processing state.
enum ProcessingPurpose: Equatable {
    case reflection
    case calmingExercise
}

/// Capture states for the primary recording / reflection flow.
enum CaptureState: Equatable {
    case idle
    case listening
    case processing(ProcessingPurpose)
    case reflecting(ReflectionConversation)
    case crisis(CrisisKind)
    case saved
    case error
}

/// Coordinates speech capture, conversational AI reflection, and persistence.
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
    @Published var draftText = ""
    @Published var folderToOpen: ThoughtFolder?
    @Published var pendingToolNavigation: CopingTool?
    @Published private(set) var isContinueReflecting = false

    private let speechService = SpeechRecognitionService()
    private let reflectionService: ReflectionAnalysisService
    private var chatClient: any ChatClient
    private var sourceLabel: String
    private var observationTask: Task<Void, Never>?
    /// True while listening as a “continue reflecting” turn (no new Thought insert).
    private var isContinueListening = false
    private var activeHistory: [ChatMessage] = []

    /// Creates a capture coordinator with optional custom services.
    /// - Parameters:
    ///   - reflectionService: Used for Library-compatible analysis / folder suggestions.
    ///   - chatClient: Conversational client; defaults to the availability router choice.
    init(
        reflectionService: ReflectionAnalysisService? = nil,
        chatClient: (any ChatClient)? = nil
    ) {
        self.reflectionService = reflectionService ?? ReflectionAnalysisService()
        if let chatClient {
            self.chatClient = chatClient
            self.sourceLabel = "Offline Nest assistant"
        } else {
            let routed = ChatClientRouter.makeClient()
            self.chatClient = routed.client
            self.sourceLabel = routed.sourceLabel
        }
    }

    /// Refreshes which AI backend Nest will use (e.g. after enabling Apple Intelligence).
    func refreshChatClient() {
        guard case .idle = captureState else { return }
        let routed = ChatClientRouter.makeClient()
        chatClient = routed.client
        sourceLabel = routed.sourceLabel
        if let foundation = chatClient as? FoundationModelsChatClient {
            foundation.prewarm()
        }
    }

    /// Whether the flow is waiting on AI work (reflection or calming exercise setup).
    var isProcessing: Bool {
        if case .processing = captureState { return true }
        return false
    }

    /// Begins a new voice capture session for the first share or a continue turn.
    func startRecording(continuing: Bool = false) async {
        guard captureState != .listening, !isProcessing else { return }

        let granted = await speechService.requestPermissions()
        guard granted else {
            captureState = .error
            errorMessage = speechService.errorMessage
            return
        }

        do {
            try await speechService.startListening()
            isContinueListening = continuing
            captureState = .listening
            errorMessage = nil
            if !continuing {
                folderToOpen = nil
            }
            beginObservingSpeechService()
        } catch {
            captureState = .error
            errorMessage = error.localizedDescription
        }
    }

    /// Ends capture and routes transcript into a new or continued reflection.
    func stopRecording(folders: [ThoughtFolder], modelContext: ModelContext) async {
        guard captureState == .listening else { return }

        captureState = .processing(.reflection)
        observationTask?.cancel()

        let result = await speechService.stopListening()
        partialTranscript = result.transcript
        waveformSamples = []
        speechDensity = 0
        currentAmplitude = 0

        let transcript = result.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let continuing = isContinueListening
        isContinueListening = false

        if continuing {
            guard !transcript.isEmpty else {
                restoreTurnOrIdle()
                errorMessage = "Nothing was captured. Try speaking again."
                return
            }
            await appendConversationTurn(text: transcript)
            return
        }

        guard !transcript.isEmpty || result.audioFileName != nil else {
            captureState = .error
            errorMessage = "Nothing was captured. Try speaking again."
            return
        }

        await beginReflectionSession(
            text: transcript,
            audioFileName: result.audioFileName,
            duration: result.duration,
            folders: folders,
            modelContext: modelContext
        )
    }

    /// Sends optional typed text as the first share or a continue turn.
    /// - Parameters:
    ///   - folders: Available folders for routing on the first save.
    ///   - modelContext: SwiftData context for persisting the first Thought.
    func submitText(folders: [ThoughtFolder], modelContext: ModelContext) async {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard captureState != .listening, !isProcessing else { return }

        draftText = ""

        if isContinueReflecting {
            captureState = .processing(.reflection)
            await appendConversationTurn(text: text)
            return
        }

        captureState = .processing(.reflection)
        await beginReflectionSession(
            text: text,
            audioFileName: nil,
            duration: 0,
            folders: folders,
            modelContext: modelContext
        )
    }

    /// Returns to the Voice tab home UI so the user can share another turn.
    func beginContinueReflecting() {
        guard case .reflecting = captureState else { return }
        isContinueReflecting = true
        captureState = .idle
    }

    /// Starts voice capture for a continue turn.
    func startContinueRecording() async {
        await startRecording(continuing: true)
    }

    /// Finishes the session and shows summary + activity invitations.
    func finishReflecting() async {
        guard case .reflecting(let conversation) = captureState else { return }
        captureState = .processing(.calmingExercise)
        do {
            let closing = try await chatClient.reflectionClosing(history: conversation.history)
            var updated = conversation
            updated.phase = .showingClosing(closing)
            captureState = .reflecting(updated)
        } catch {
            let fallback = ReflectionClosing(
                summary: "Thanks for sharing with Nest. You can revisit this anytime in your library.",
                invitationLine: ReflectionClosing.defaultInvitationLine,
                suggestedActivities: [.softUnwind, .guidedBreathing, .kindNote]
            )
            var updated = conversation
            updated.phase = .showingClosing(fallback)
            captureState = .reflecting(updated)
        }
    }

    func dismissReflection() {
        activeHistory = []
        isContinueListening = false
        isContinueReflecting = false
        captureState = .idle
    }

    func dismissCrisis() {
        activeHistory = []
        isContinueReflecting = false
        captureState = .idle
    }

    func requestToolNavigation(_ tool: CopingTool) {
        pendingToolNavigation = tool
        activeHistory = []
        isContinueReflecting = false
        captureState = .idle
    }

    // MARK: - Private

    private func beginReflectionSession(
        text: String,
        audioFileName: String?,
        duration: TimeInterval,
        folders: [ThoughtFolder],
        modelContext: ModelContext
    ) async {
        let analysis: ReflectionAnalysis
        let turn: ReflectionTurn

        do {
            turn = try await chatClient.reflectionTurn(for: text, history: [])
            let suggestedFolder = Self.suggestedFolderName(in: text, folders: folders)
            analysis = ReflectionAnalysis(
                reflection: turn.reflection,
                stressor: turn.stressor,
                emotion: turn.emotion,
                recommendedTool: turn.recommendedTool,
                suggestedFolder: turn.crisis ? nil : suggestedFolder,
                crisisKind: turn.crisisKind
            )
        } catch {
            if let serviceAnalysis = try? await reflectionService.analyze(
                transcript: text,
                availableFolders: folders
            ) {
                analysis = serviceAnalysis
                let summary = VoiceNoteSummaryHelper.summarize(transcript: text)
                turn = ReflectionTurn(
                    reflection: serviceAnalysis.reflection,
                    themeNotes: [],
                    followUpQuestion: nil,
                    feelsNaturalPause: true,
                    crisisKind: serviceAnalysis.crisisKind,
                    recommendedTool: serviceAnalysis.recommendedTool,
                    stressor: serviceAnalysis.stressor,
                    emotion: serviceAnalysis.emotion,
                    title: summary.title,
                    preview: summary.preview
                )
            } else {
                let fallback = ReflectionAnalysisService.fallback()
                analysis = fallback
                let summary = VoiceNoteSummaryHelper.summarize(transcript: text)
                turn = ReflectionTurn(
                    reflection: fallback.reflection,
                    themeNotes: [],
                    followUpQuestion: nil,
                    feelsNaturalPause: true,
                    crisisKind: .none,
                    recommendedTool: fallback.recommendedTool,
                    stressor: fallback.stressor,
                    emotion: fallback.emotion,
                    title: summary.title,
                    preview: summary.preview
                )
            }
        }

        let destinationFolder = FolderSuggestionResolver.resolve(
            suggestedFolder: analysis.suggestedFolder,
            folders: folders
        )

        let displayText: String
        if text.isEmpty {
            displayText = audioFileName != nil ? "Voice memo" : destinationFolder.name
        } else {
            displayText = text
        }

        let fallbackSummary = VoiceNoteSummaryHelper.summarize(transcript: text.isEmpty ? displayText : text)
        let noteTitle = turn.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? fallbackSummary.title
            : turn.title
        let notePreview = turn.preview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? fallbackSummary.preview
            : turn.preview

        let thought = Thought(
            text: displayText,
            fullTranscript: text.isEmpty ? nil : text,
            audioFileName: audioFileName,
            duration: duration,
            reflection: analysis.crisis ? nil : analysis.reflection,
            stressor: analysis.crisis ? nil : analysis.stressor,
            emotion: analysis.crisis ? nil : analysis.emotion,
            recommendedToolRaw: analysis.crisis ? nil : analysis.recommendedTool.rawValue,
            isCrisis: analysis.crisis,
            title: noteTitle,
            preview: notePreview,
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
                captureState = .crisis(analysis.crisisKind)
                return
            }

            var history: [ChatMessage] = []
            if !text.isEmpty {
                history.append(ChatMessage(role: .user, text: text))
                history.append(ChatMessage(role: .assistant, text: turn.assistantHistoryText))
            }
            activeHistory = history

            let conversation = ReflectionConversation(
                phase: .showingTurn(turn),
                history: history,
                sourceLabel: sourceLabel
            )
            captureState = .reflecting(conversation)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } catch {
            captureState = .error
            errorMessage = "Could not save your thought."
        }
    }

    private func appendConversationTurn(text: String) async {
        let history = activeHistory
        do {
            let turn = try await chatClient.reflectionTurn(for: text, history: history)
            if turn.crisis {
                captureState = .crisis(turn.crisisKind)
                return
            }

            var nextHistory = history
            nextHistory.append(ChatMessage(role: .user, text: text))
            nextHistory.append(ChatMessage(role: .assistant, text: turn.assistantHistoryText))
            activeHistory = nextHistory

            let conversation = ReflectionConversation(
                phase: .showingTurn(turn),
                history: nextHistory,
                sourceLabel: sourceLabel
            )
            isContinueReflecting = false
            captureState = .reflecting(conversation)
        } catch {
            restoreTurnOrIdle()
            errorMessage = "Nest couldn’t reflect just now. Try again when you’re ready."
        }
    }

    private func restoreTurnOrIdle() {
        isContinueReflecting = false
        if let lastAssistant = activeHistory.last(where: { $0.role == .assistant }) {
            let turn = ReflectionTurn(
                reflection: lastAssistant.text,
                themeNotes: [],
                followUpQuestion: nil,
                feelsNaturalPause: true,
                crisisKind: .none,
                recommendedTool: .softUnwind,
                stressor: "daily life",
                emotion: "uncertainty",
                title: "",
                preview: ""
            )
            captureState = .reflecting(
                ReflectionConversation(
                    phase: .showingTurn(turn),
                    history: activeHistory,
                    sourceLabel: sourceLabel
                )
            )
        } else {
            captureState = .idle
        }
    }

    /// Suggests a custom folder when its name appears in the user text.
    /// - Parameters:
    ///   - text: User transcript or typed message.
    ///   - folders: Available thought folders.
    /// - Returns: Matching custom folder name, or nil.
    private static func suggestedFolderName(in text: String, folders: [ThoughtFolder]) -> String? {
        let lower = text.lowercased()
        return folders
            .filter { !$0.isInbox }
            .first { lower.contains($0.name.lowercased()) }?
            .name
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
