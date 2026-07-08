import SwiftData
import SwiftUI

/// Sheet for creating a new keyword-routed folder.
struct CreateFolderSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ThoughtFolder.sortOrder) private var folders: [ThoughtFolder]

    @State private var folderName = ""
    @State private var selectedColor: FolderColor = .blue
    @State private var errorMessage: String?
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                NestBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        previewCard
                        nameField
                        colorPicker
                        keywordHint
                    }
                    .padding(24)
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(NestTheme.secondaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") { createFolder() }
                        .fontWeight(.semibold)
                        .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { isNameFocused = true }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var previewCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(selectedColor.gradient)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: "folder.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(folderName.isEmpty ? "Folder Name" : folderName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(NestTheme.primaryText)
                Text("Say \"\(spokenKeyword)\" to save here")
                    .font(.subheadline)
                    .foregroundStyle(NestTheme.secondaryText)
            }
            Spacer()
        }
        .padding(18)
        .background(cardBackground)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Name")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NestTheme.secondaryText)

            TextField("e.g. School, Ideas, Lyrics", text: $folderName)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(NestTheme.primaryText)
                .padding(16)
                .background(cardBackground)
                .focused($isNameFocused)
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NestTheme.secondaryText)

            HStack(spacing: 14) {
                ForEach(FolderColor.selectable, id: \.rawValue) { color in
                    Button {
                        selectedColor = color
                    } label: {
                        Circle()
                            .fill(color.gradient)
                            .frame(width: 40, height: 40)
                            .overlay {
                                if selectedColor == color {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(Color.white.opacity(selectedColor == color ? 0.9 : 0), lineWidth: 2)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var keywordHint: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.9))
            }

            Text("Your folder name becomes the spoken keyword. Say it first when capturing a thought.")
                .font(.footnote)
                .foregroundStyle(NestTheme.secondaryText)
        }
    }

    private var spokenKeyword: String {
        let trimmed = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "keyword" : trimmed
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(NestTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
            )
    }

    private func createFolder() {
        do {
            _ = try LibraryViewModel.createFolder(
                name: folderName,
                colorName: selectedColor.rawValue,
                folders: folders,
                in: modelContext
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CreateFolderSheet()
        .modelContainer(for: [Thought.self, ThoughtFolder.self], inMemory: true)
}
