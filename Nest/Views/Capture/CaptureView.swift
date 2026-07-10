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

                if isRecording {
                    recordingLayout
                } else if viewModel.captureState == .processing {
                    processingLayout
                } else {
                    homeLayout
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isLibraryPresented) {
                LibraryView()
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
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isRecording)
        .toolbar(isRecording || viewModel.captureState == .processing ? .hidden : .visible, for: .tabBar)
    }

    private var homeLayout: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 8)

            Spacer()

            routingHint
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

            EmptyThoughtsButton(isDisabled: false) {
                Task { await viewModel.startRecording() }
            }
            .padding(.horizontal, 24)

            if let error = viewModel.errorMessage, viewModel.captureState == .error {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Say a folder name first")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NestTheme.secondaryText)
                    .padding(.horizontal, 24)

                FolderChipRow(folders: folders) { folder in
                    viewModel.folderToOpen = folder
                }
            }
            .padding(.bottom, 28)
        }
    }

    /// Explains that the first spoken word routes the memo into a matching folder.
    private var routingHint: some View {
        VStack(spacing: 8) {
            Text("Speak the folder name first")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NestTheme.primaryText)

            Text("Example: “Music, I left my heart in the chorus.”")
                .font(.footnote)
                .foregroundStyle(NestTheme.secondaryText)
                .multilineTextAlignment(.center)

            Text("Nest saves it to that folder automatically.")
                .font(.caption)
                .foregroundStyle(NestTheme.secondaryText.opacity(0.9))
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
            Text("Transcribing…")
                .font(.subheadline)
                .foregroundStyle(NestTheme.secondaryText)
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
            .accessibilityLabel("Open library")
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
    CaptureView()
        .modelContainer(for: [Thought.self, ThoughtFolder.self], inMemory: true)
}
