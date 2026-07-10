import SwiftData
import SwiftUI

/// Library home listing all folders with management options.
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ThoughtFolder.sortOrder) private var folders: [ThoughtFolder]
    @State private var isCreateFolderPresented = false
    @State private var folderToRename: ThoughtFolder?
    @State private var folderToDelete: ThoughtFolder?
    @State private var editMode: EditMode = .inactive

    private var userFolders: [ThoughtFolder] {
        folders.filter { !$0.isInbox }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var inboxFolder: ThoughtFolder? {
        folders.first(where: \.isInbox)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestBackground()

                List {
                    if let inboxFolder {
                        Section {
                            NavigationLink {
                                FolderDetailView(folder: inboxFolder)
                            } label: {
                                FolderListRow(folder: inboxFolder, thoughtCount: inboxFolder.thoughts.count)
                            }
                        }
                    }

                    Section {
                        ForEach(userFolders, id: \.id) { folder in
                            NavigationLink {
                                FolderDetailView(folder: folder)
                            } label: {
                                FolderListRow(folder: folder, thoughtCount: folder.thoughts.count)
                            }
                            .contextMenu {
                                Button("Rename") { folderToRename = folder }
                                Button("Delete", role: .destructive) { folderToDelete = folder }
                            }
                        }
                        .onMove(perform: moveFolders)
                        .onDelete(perform: deleteFoldersAtOffsets)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .environment(\.editMode, $editMode)
            }
            .navigationTitle("Folders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(NestTheme.secondaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        EditButton()
                            .foregroundStyle(NestTheme.primaryText)
                        Button {
                            isCreateFolderPresented = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(NestTheme.primaryText)
                        }
                        .accessibilityLabel("Create folder")
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $isCreateFolderPresented) {
                CreateFolderSheet()
            }
            .sheet(item: $folderToRename) { folder in
                RenameFolderSheet(folder: folder)
            }
            .alert("Delete Folder?", isPresented: Binding(
                get: { folderToDelete != nil },
                set: { if !$0 { folderToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let folder = folderToDelete {
                        try? LibraryViewModel.deleteFolder(folder, folders: folders, in: modelContext)
                    }
                    folderToDelete = nil
                }
                Button("Cancel", role: .cancel) { folderToDelete = nil }
            } message: {
                if let folder = folderToDelete {
                    Text("Thoughts in \"\(folder.name)\" will move to Inbox.")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func moveFolders(from source: IndexSet, to destination: Int) {
        var ordered = userFolders
        ordered.move(fromOffsets: source, toOffset: destination)
        LibraryViewModel.moveFolders(ordered, allFolders: folders, in: modelContext)
    }

    private func deleteFoldersAtOffsets(_ offsets: IndexSet) {
        for index in offsets {
            let folder = userFolders[index]
            folderToDelete = folder
        }
    }
}

private struct FolderListRow: View {
    let folder: ThoughtFolder
    let thoughtCount: Int

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(FolderColor.gradient(for: folder.colorName))
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: folderIcon)
                        .font(.title3)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.headline)
                    .foregroundStyle(NestTheme.primaryText)
                if folder.isInbox {
                    Text("\(thoughtCount) uncategorized")
                        .font(.caption)
                        .foregroundStyle(NestTheme.secondaryText)
                } else {
                    Text("Say \"\(folder.name)\" · \(thoughtCount) memos")
                        .font(.caption)
                        .foregroundStyle(NestTheme.secondaryText)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var folderIcon: String {
        switch folder.name.lowercased() {
        case "music": "music.note"
        case "homework", "school": "books.vertical.fill"
        case "work": "briefcase.fill"
        default: folder.isInbox ? "tray.fill" : "folder.fill"
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [Thought.self, ThoughtFolder.self], inMemory: true)
}
