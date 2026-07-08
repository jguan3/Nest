import SwiftData
import SwiftUI

/// Primary capture screen — opens directly on launch for low friction.
struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ThoughtFolder.sortOrder) private var folders: [ThoughtFolder]
    @StateObject private var viewModel = CaptureViewModel()
    @State private var isLibraryPresented = false

    private var isRecording: Bool {
        viewModel.captureState == .listening
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestBackground()

                VStack(spacing: 0) {
                    header
                        .padding(.top, 8)

                    Spacer()

                    if isRecording {
                        recordingWaveform
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else {
                        transcriptCard
                            .padding(.horizontal, 20)
                            .transition(.opacity)
                    }

                    Spacer()

                    VStack(spacing: 20) {
                        captureControls
                        if !isRecording {
                            FolderChipRow(folders: folders)
                                .padding(.horizontal, 20)
                            hintText
                        }
                    }
                    .padding(.bottom, 28)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isRecording)

                if let folderName = viewModel.savedFolderName,
                   let colorName = viewModel.savedFolderColorName {
                    VStack {
                        SavedToast(folderName: folderName, colorName: colorName)
                            .padding(.top, 8)
                        Spacer()
                    }
                    .animation(.spring(response: 0.35), value: viewModel.savedFolderName)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isLibraryPresented) {
                LibraryView()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nest")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(NestTheme.primaryText)
                Text(isRecording ? "Let it out…" : "Catch it before it's gone")
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
            .accessibilityLabel("Open library")
        }
        .padding(.horizontal, 24)
    }

    private var transcriptCard: some View {
        VStack(spacing: 12) {
            Text(displayTranscript)
                .font(.title2.weight(viewModel.partialTranscript.isEmpty ? .regular : .medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    viewModel.partialTranscript.isEmpty ? NestTheme.secondaryText : NestTheme.primaryText
                )
                .frame(minHeight: 100)
                .frame(maxWidth: .infinity)
                .animation(.easeInOut(duration: 0.15), value: viewModel.partialTranscript)
        }
        .padding(24)
        .background(cardBackground)
    }

    private var recordingWaveform: some View {
        VStack(spacing: 20) {
            LiveWaveformView(
                samples: viewModel.waveformSamples,
                density: viewModel.speechDensity
            )
            .frame(height: 140)
            .padding(.horizontal, 8)
            .padding(.vertical, 24)
            .background(cardBackground)

            if !viewModel.partialTranscript.isEmpty {
                Text(viewModel.partialTranscript)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(NestTheme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var captureControls: some View {
        switch viewModel.captureState {
        case .listening:
            StopRecordingButton {
                Task {
                    await viewModel.stopRecording(folders: folders, modelContext: modelContext)
                }
            }
        case .processing:
            Text("Saving…")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NestTheme.secondaryText)
        default:
            EmptyThoughtsButton(isDisabled: viewModel.captureState == .processing) {
                Task { await viewModel.startRecording() }
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(NestTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
            )
    }

    private var displayTranscript: String {
        if !viewModel.partialTranscript.isEmpty {
            return viewModel.partialTranscript
        }
        if let error = viewModel.errorMessage, viewModel.captureState == .error {
            return error
        }
        return "Your words will appear here"
    }

    private var hintText: some View {
        Text("Say a folder name, then your thought")
            .font(.footnote)
            .foregroundStyle(NestTheme.secondaryText.opacity(0.8))
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: [Thought.self, ThoughtFolder.self], inMemory: true)
}
