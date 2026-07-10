import SwiftUI

/// Horizontal row of folder keyword chips shown on the capture screen.
struct FolderChipRow: View {
    let folders: [ThoughtFolder]
    var onSelect: ((ThoughtFolder) -> Void)? = nil

    private var keywordFolders: [ThoughtFolder] {
        folders.filter { !$0.isInbox }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(keywordFolders, id: \.id) { folder in
                    Button {
                        onSelect?(folder)
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(FolderColor.from(name: folder.colorName))
                                .frame(width: 8, height: 8)
                            Text(folder.name)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(NestTheme.primaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(FolderColor.from(name: folder.colorName).opacity(0.18))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(FolderColor.from(name: folder.colorName).opacity(0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(onSelect == nil)
                    .accessibilityLabel("Open \(folder.name) folder")
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 20)
    }
}
