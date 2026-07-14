import SwiftData
import SwiftUI

/// Voice memo card with playback, AI reflection, transcription, and folder reassignment.
struct VoiceMemoCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ThoughtFolder.sortOrder) private var folders: [ThoughtFolder]

    let thought: Thought
    let colorName: String
    let isPlaying: Bool
    let onPlay: () -> Void
    let onDelete: () -> Void

    @State private var isTranscriptionExpanded = false
    @State private var transcriptionText = ""
    @State private var isTranscribing = false
    @State private var showDeleteConfirmation = false
    @State private var showMoveToFolder = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(thought.createdAt.formatted(.dateTime.weekday(.abbreviated).month(.defaultDigits).day()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(NestTheme.primaryText)
                Spacer()
                Text(thought.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(NestTheme.secondaryText)

                Menu {
                    Button("Move to…") { showMoveToFolder = true }
                    Button("Delete", role: .destructive) { showDeleteConfirmation = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.subheadline)
                        .foregroundStyle(NestTheme.secondaryText)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Memo options")
            }

            if thought.hasReflection, let reflection = thought.reflection {
                Text(reflection)
                    .font(.body)
                    .foregroundStyle(NestTheme.primaryText)
                    .lineSpacing(4)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(NestTheme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                            )
                    )
            }

            HStack(spacing: 14) {
                Button(action: onPlay) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(NestTheme.primaryText)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .opacity(thought.hasVoiceMemo ? 1 : 0.35)
                .disabled(!thought.hasVoiceMemo)

                StaticWaveformBars()
                    .frame(height: 36)

                Spacer()

                Text(thought.formattedDuration)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(NestTheme.secondaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(FolderColor.from(name: colorName).opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(FolderColor.from(name: colorName).opacity(0.35), lineWidth: 1)
                    )
            )

            if let folderName = thought.folder?.name {
                Text("In \(folderName)")
                    .font(.caption)
                    .foregroundStyle(NestTheme.secondaryText)
            }

            Button {
                toggleTranscription()
            } label: {
                Text(isTranscriptionExpanded ? "Hide transcription" : "View transcription")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(NestTheme.secondaryText)
            }
            .buttonStyle(.plain)

            if isTranscriptionExpanded {
                Group {
                    if isTranscribing {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(.white)
                            Text("Transcribing…")
                                .font(.subheadline)
                                .foregroundStyle(NestTheme.secondaryText)
                        }
                    } else {
                        Text(transcriptionText)
                            .font(.body)
                            .foregroundStyle(NestTheme.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .alert("Delete voice memo?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the recording and transcription permanently.")
        }
        .confirmationDialog("Move to folder", isPresented: $showMoveToFolder, titleVisibility: .visible) {
            ForEach(folders) { folder in
                Button(folder.name) {
                    moveThought(to: folder)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func moveThought(to folder: ThoughtFolder) {
        if let currentFolder = thought.folder, currentFolder.id != folder.id {
            currentFolder.thoughts.removeAll { $0.id == thought.id }
        }
        thought.folder = folder
        if !folder.thoughts.contains(where: { $0.id == thought.id }) {
            folder.thoughts.append(thought)
        }
        try? modelContext.save()
    }

    private func toggleTranscription() {
        withAnimation(.spring(response: 0.3)) {
            isTranscriptionExpanded.toggle()
        }

        guard isTranscriptionExpanded else { return }

        if isTranscribing { return }

        if let cached = thought.fullTranscript, !cached.isEmpty {
            transcriptionText = cached
            return
        }

        Task { await fetchTranscription() }
    }

    private func fetchTranscription() async {
        isTranscribing = true
        let text = await LibraryViewModel.loadTranscription(
            for: thought,
            folders: folders,
            in: modelContext
        )
        transcriptionText = text
        isTranscribing = false
    }
}

private struct StaticWaveformBars: View {
    private let barHeights: [CGFloat] = [0.3, 0.55, 0.8, 0.45, 0.7, 0.5, 0.9, 0.4, 0.65, 0.35, 0.75, 0.5]

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(barHeights.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(NestTheme.primaryText.opacity(0.85))
                    .frame(width: 3, height: 28 * barHeights[index])
            }
        }
    }
}
