import SwiftData
import SwiftUI

/// Primary capture screen — voice or optional text into conversational reflection.
struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ThoughtFolder.sortOrder) private var folders: [ThoughtFolder]
    @ObservedObject var viewModel: CaptureViewModel
    @State private var isLibraryPresented = false
    @FocusState private var isTextFieldFocused: Bool

    private var isRecording: Bool {
        viewModel.captureState == .listening
    }

    private var isProcessing: Bool {
        viewModel.isProcessing
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestBackground()

                if isRecording {
                    recordingLayout
                } else if isProcessing {
                    processingLayout
                } else {
                    homeLayout
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isLibraryPresented) {
                VoiceNotesHistoryView()
            }
            .sheet(isPresented: Binding(
                get: { viewModel.folderToOpen != nil },
                set: { if !$0 { viewModel.folderToOpen = nil } }
            )) {
                if let folder = viewModel.folderToOpen {
                    NavigationStack {
                        FolderDetailView(folder: folder)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Done") {
                                        viewModel.folderToOpen = nil
                                    }
                                    .foregroundStyle(NestTheme.primaryText)
                                }
                            }
                    }
                }
            }
            .fullScreenCover(isPresented: reflectingBinding) {
                if case .reflecting(let conversation) = viewModel.captureState {
                    ReflectionResultView(
                        conversation: conversation,
                        savedFolderName: viewModel.savedFolderName,
                        savedFolderColorName: viewModel.savedFolderColorName,
                        onContinueReflecting: {
                            viewModel.beginContinueReflecting()
                        },
                        onDoneForNow: {
                            Task { await viewModel.finishReflecting() }
                        },
                        onSelectActivity: { tool in
                            viewModel.requestToolNavigation(tool)
                        },
                        onDismissClosing: {
                            viewModel.dismissReflection()
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: crisisBinding) {
                crisisSupportCover
            }
            .onAppear {
                viewModel.refreshChatClient()
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isRecording)
        .toolbar(isRecording || isProcessing ? .hidden : .visible, for: .tabBar)
    }

    /// Chooses self-harm or harm-to-others support UI from the active crisis kind.
    @ViewBuilder
    private var crisisSupportCover: some View {
        if case .crisis(let kind) = viewModel.captureState {
            switch kind {
            case .harmToOthers:
                HarmToOthersSupportView(
                    savedFolderName: viewModel.savedFolderName,
                    savedFolderColorName: viewModel.savedFolderColorName,
                    onDismiss: { viewModel.dismissCrisis() }
                )
            case .selfHarm, .none:
                CrisisSupportView(
                    savedFolderName: viewModel.savedFolderName,
                    savedFolderColorName: viewModel.savedFolderColorName,
                    onDismiss: { viewModel.dismissCrisis() }
                )
            }
        } else {
            CrisisSupportView(
                savedFolderName: viewModel.savedFolderName,
                savedFolderColorName: viewModel.savedFolderColorName,
                onDismiss: { viewModel.dismissCrisis() }
            )
        }
    }

    private var reflectingBinding: Binding<Bool> {
        Binding(
            get: {
                if case .reflecting = viewModel.captureState { return true }
                return false
            },
            set: { isPresented in
                // Avoid wiping the session when state briefly leaves `.reflecting`
                // for voice continue / processing.
                if !isPresented, case .reflecting = viewModel.captureState {
                    viewModel.dismissReflection()
                }
            }
        )
    }

    private var crisisBinding: Binding<Bool> {
        Binding(
            get: {
                if case .crisis = viewModel.captureState { return true }
                return false
            },
            set: { if !$0 { viewModel.dismissCrisis() } }
        )
    }

    private var homeLayout: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 8)

            Spacer()
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }

            captureHint
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

            EmptyThoughtsButton(isDisabled: false) {
                isTextFieldFocused = false
                if viewModel.isContinueReflecting {
                    Task { await viewModel.startContinueRecording() }
                } else {
                    Task { await viewModel.startRecording() }
                }
            }
            .padding(.horizontal, 24)

            textComposer
                .padding(.horizontal, 24)
                .padding(.top, 16)

            if let error = viewModel.errorMessage, viewModel.captureState == .error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
            }

            Spacer()
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }

            VStack(alignment: .leading, spacing: 8) {
                Text("Your folders")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NestTheme.secondaryText)
                    .padding(.horizontal, 24)

                FolderChipRow(folders: folders) { folder in
                    isTextFieldFocused = false
                    viewModel.folderToOpen = folder
                }
            }
            .padding(.bottom, 28)
        }
    }

    private var textComposer: some View {
        HStack(spacing: 10) {
            TextField("Or type what's on your mind…", text: $viewModel.draftText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(14)
                .foregroundStyle(NestTheme.primaryText)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(NestTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                        )
                )
                .lineLimit(1...4)
                .focused($isTextFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    isTextFieldFocused = false
                }

            Button {
                isTextFieldFocused = false
                Task {
                    await viewModel.submitText(folders: folders, modelContext: modelContext)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? NestTheme.secondaryText.opacity(0.5)
                            : NestTheme.primaryText
                    )
            }
            .disabled(viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send typed reflection")
        }
    }

    private var captureHint: some View {
        VStack(spacing: 8) {
            Text(viewModel.isContinueReflecting ? "Share a little more" : "Share freely")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NestTheme.primaryText)

            Text(
                viewModel.isContinueReflecting
                    ? "Speak or type — Nest will only see the words, not how you shared them."
                    : "Speak or type. Nest will reflect with you and offer a gentle next step when you're ready."
            )
                .font(.footnote)
                .foregroundStyle(NestTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NestTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                )
        )
    }

    private var processingLayout: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
            Text(processingMessage)
                .font(.subheadline)
                .foregroundStyle(NestTheme.secondaryText)
        }
    }

    private var processingMessage: String {
        guard case .processing(let purpose) = viewModel.captureState else {
            return "Reflecting on what you shared…"
        }
        switch purpose {
        case .reflection:
            return "Reflecting on what you shared…"
        case .calmingExercise:
            return "Preparing your calming exercise…"
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Voice")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(NestTheme.primaryText)
                Text("Catch it before it's gone")
                    .font(.subheadline)
                    .foregroundStyle(NestTheme.secondaryText)
            }
            Spacer()
            Button {
                isLibraryPresented = true
            } label: {
                Image(systemName: "folder.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(NestTheme.primaryText)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(NestTheme.cardBackground)
                            .overlay(Circle().strokeBorder(NestTheme.cardStroke, lineWidth: 1))
                    )
            }
            .accessibilityLabel("Open History")
        }
        .padding(.horizontal, 24)
    }

    private var recordingLayout: some View {
        RecordingScreenView(
            amplitude: viewModel.currentAmplitude,
            density: viewModel.speechDensity,
            samples: viewModel.waveformSamples,
            partialTranscript: viewModel.partialTranscript,
            onStop: {
                Task {
                    await viewModel.stopRecording(folders: folders, modelContext: modelContext)
                }
            }
        )
    }
}

#Preview {
    CaptureView(viewModel: CaptureViewModel())
        .modelContainer(for: [Thought.self, ThoughtFolder.self], inMemory: true)
}
