import SwiftData
import SwiftUI

/// Detail view for a single folder's voice memos and transcriptions.
struct FolderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ThoughtFolder.sortOrder) private var folders: [ThoughtFolder]
    @StateObject private var player = VoiceMemoPlayer()

    let folder: ThoughtFolder
    @State private var folderToRename: ThoughtFolder?
    @State private var showDeleteConfirmation = false

    private var thoughts: [Thought] {
        folder.thoughts.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ZStack {
            NestBackground()

            ScrollView {
                if thoughts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "waveform")
                            .font(.system(size: 40))
                            .foregroundStyle(NestTheme.secondaryText)
                        Text("No voice memos yet")
                            .font(.headline)
                            .foregroundStyle(NestTheme.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 18) {
                        ForEach(thoughts) { thought in
                            VoiceMemoCard(
                                thought: thought,
                                colorName: folder.colorName,
                                isPlaying: player.playingThoughtID == thought.id && player.isPlaying,
                                onPlay: { player.togglePlayback(for: thought) },
                                onDelete: {
                                    if player.playingThoughtID == thought.id {
                                        player.stop()
                                    }
                                    LibraryViewModel.delete(thought, in: modelContext)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
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
        .onDisappear { player.stop() }
    }
}
