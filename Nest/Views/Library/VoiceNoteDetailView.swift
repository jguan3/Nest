import SwiftData
import SwiftUI

/// Full detail for a saved voice note — transcription, reflection, and playback.
struct VoiceNoteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var player = VoiceMemoPlayer()

    let thought: Thought
    @State private var showEditTitle = false
    @State private var editedTitle = ""
    @State private var didDelete = false

    private var colorName: String {
        thought.folder?.colorName ?? "gray"
    }

    var body: some View {
        ZStack {
            NestBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Button {
                        editedTitle = thought.displayTitle
                        showEditTitle = true
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(thought.displayTitle)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(NestTheme.primaryText)
                                .multilineTextAlignment(.leading)
                            Image(systemName: "pencil")
                                .font(.subheadline)
                                .foregroundStyle(NestTheme.secondaryText)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit title")
                    .accessibilityHint("Double tap to rename this voice note")

                    Text(thought.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(NestTheme.secondaryText)

                    Button {
                        toggleOvercome()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: thought.isOvercome ? "checkmark.seal.fill" : "checkmark.seal")
                            Text(thought.isOvercome ? "Marked as overcome" : "Mark as overcome")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(
                            thought.isOvercome
                                ? Color(red: 0.55, green: 0.85, blue: 0.65)
                                : NestTheme.primaryText
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(NestTheme.cardBackground)
                                .overlay(Capsule().strokeBorder(NestTheme.cardStroke, lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Marks that you have moved past this note")

                    VoiceMemoCard(
                        thought: thought,
                        colorName: colorName,
                        isPlaying: player.playingThoughtID == thought.id && player.isPlaying,
                        onPlay: { player.togglePlayback(for: thought) },
                        onDelete: {
                            player.stop()
                            LibraryViewModel.delete(thought, in: modelContext)
                            didDelete = true
                            dismiss()
                        }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .navigationTitle("Voice Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("Edit Title", isPresented: $showEditTitle) {
            TextField("Title", text: $editedTitle)
            Button("Save") { saveTitle() }
            Button("Cancel", role: .cancel) {}
        }
        .onDisappear {
            if !didDelete {
                player.stop()
            }
        }
    }

    /// Saves the edited title without touching reflection or transcript.
    private func saveTitle() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        thought.title = trimmed
        do {
            try modelContext.save()
        } catch {
            print("Could not save voice note title: \(error)")
        }
    }

    /// Toggles the overcome flag for this note.
    private func toggleOvercome() {
        thought.isOvercome.toggle()
        do {
            try modelContext.save()
        } catch {
            thought.isOvercome.toggle()
            print("Could not update overcome state: \(error)")
        }
    }
}
