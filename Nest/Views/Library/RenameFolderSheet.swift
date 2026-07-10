import SwiftData
import SwiftUI

/// Sheet for renaming an existing folder.
struct RenameFolderSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ThoughtFolder.sortOrder) private var folders: [ThoughtFolder]

    let folder: ThoughtFolder

    @State private var folderName: String
    @State private var errorMessage: String?
    @FocusState private var isNameFocused: Bool

    init(folder: ThoughtFolder) {
        self.folder = folder
        _folderName = State(initialValue: folder.name)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestBackground()

                VStack(alignment: .leading, spacing: 20) {
                    TextField("Folder name", text: $folderName)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .foregroundStyle(NestTheme.primaryText)
                        .padding(16)
                        .background(cardBackground)
                        .focused($isNameFocused)

                    Text("Say \"\(spokenKeyword)\" to route voice memos here.")
                        .font(.footnote)
                        .foregroundStyle(NestTheme.secondaryText)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.9))
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Rename Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(NestTheme.secondaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveRename() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { isNameFocused = true }
        }
        .presentationDetents([.medium])
    }

    private var spokenKeyword: String {
        let trimmed = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? folder.name : trimmed
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(NestTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
            )
    }

    private func saveRename() {
        do {
            try LibraryViewModel.renameFolder(
                folder,
                to: folderName,
                folders: folders,
                in: modelContext
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
