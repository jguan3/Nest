import SwiftData
import SwiftUI

/// Detail view for a single folder's voice memos and transcriptions.
struct FolderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ThoughtFolder.sortOrder) private var folders: [ThoughtFolder]

    let folder: ThoughtFolder
    @State private var folderToRename: ThoughtFolder?
    @State private var showDeleteConfirmation = false
    @State private var thoughtPendingDelete: Thought?
    @State private var thoughtPendingTitleEdit: Thought?
    @State private var editedTitle = ""

    private var thoughts: [Thought] {
        folder.thoughts.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ZStack {
            NestBackground()

            if thoughts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.system(size: 40))
                        .foregroundStyle(NestTheme.secondaryText)
                    Text("No voice memos yet")
                        .font(.headline)
                        .foregroundStyle(NestTheme.primaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 80)
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
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !folder.isInbox {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Rename") { folderToRename = folder }
                        Button("Delete Folder", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(NestTheme.primaryText)
                    }
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $folderToRename) { folder in
            RenameFolderSheet(folder: folder)
        }
        .alert("Delete Folder?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                try? LibraryViewModel.deleteFolder(folder, folders: folders, in: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Thoughts in \"\(folder.name)\" will move to Inbox.")
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
            Button("Save") { saveTitle() }
            Button("Cancel", role: .cancel) {
                thoughtPendingTitleEdit = nil
            }
        }
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
}
