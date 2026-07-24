import SwiftData
import SwiftUI

/// Chronological History of all saved voice notes for later revisiting (includes notes in folders).
struct VoiceNotesHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Thought.createdAt, order: .reverse) private var thoughts: [Thought]

    @State private var isFoldersPresented = false
    @State private var thoughtPendingDelete: Thought?
    @State private var thoughtPendingTitleEdit: Thought?
    @State private var editedTitle = ""

    var body: some View {
        NavigationStack {
            ZStack {
                NestBackground()

                if thoughts.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(thoughts) { thought in
                            NavigationLink {
                                VoiceNoteDetailView(thought: thought)
                            } label: {
                                VoiceNoteHistoryRow(
                                    thought: thought,
                                    onEditTitle: {
                                        thoughtPendingTitleEdit = thought
                                        editedTitle = thought.displayTitle
                                    },
                                    onToggleOvercome: {
                                        toggleOvercome(thought)
                                    }
                                )
                            }
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    thoughtPendingDelete = thought
                                }
                                Button("Edit Title") {
                                    thoughtPendingTitleEdit = thought
                                    editedTitle = thought.displayTitle
                                }
                                .tint(NestTheme.primaryText.opacity(0.7))
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(thought.isOvercome ? "Unmark" : "Overcome") {
                                    toggleOvercome(thought)
                                }
                                .tint(Color(red: 0.45, green: 0.7, blue: 0.55))
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(NestTheme.secondaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Folders") { isFoldersPresented = true }
                        .foregroundStyle(NestTheme.primaryText)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $isFoldersPresented) {
                LibraryView()
            }
            .alert("Delete voice memo?", isPresented: Binding(
                get: { thoughtPendingDelete != nil },
                set: { if !$0 { thoughtPendingDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let thought = thoughtPendingDelete {
                        LibraryViewModel.delete(thought, in: modelContext)
                    }
                    thoughtPendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    thoughtPendingDelete = nil
                }
            } message: {
                Text("This removes the recording, transcription, reflection, title, and preview permanently.")
            }
            .alert("Edit Title", isPresented: Binding(
                get: { thoughtPendingTitleEdit != nil },
                set: { if !$0 { thoughtPendingTitleEdit = nil } }
            )) {
                TextField("Title", text: $editedTitle)
                Button("Save") {
                    saveTitle()
                }
                Button("Cancel", role: .cancel) {
                    thoughtPendingTitleEdit = nil
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform")
                .font(.system(size: 40))
                .foregroundStyle(NestTheme.secondaryText)
            Text("No history yet")
                .font(.headline)
                .foregroundStyle(NestTheme.primaryText)
            Text("Your saved voice notes will show up here, even if they are sorted into folders.")
                .font(.subheadline)
                .foregroundStyle(NestTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }

    /// Writes only the title field on the pending thought.
    private func saveTitle() {
        guard let thought = thoughtPendingTitleEdit else { return }
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        thoughtPendingTitleEdit = nil
        guard !trimmed.isEmpty else { return }
        thought.title = trimmed
        do {
            try modelContext.save()
        } catch {
            print("Could not save voice note title: \(error)")
        }
    }

    /// Toggles whether a history note is marked as overcome.
    private func toggleOvercome(_ thought: Thought) {
        thought.isOvercome.toggle()
        do {
            try modelContext.save()
        } catch {
            thought.isOvercome.toggle()
            print("Could not update overcome state: \(error)")
        }
    }
}

#Preview {
    VoiceNotesHistoryView()
}
