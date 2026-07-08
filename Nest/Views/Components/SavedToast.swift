import SwiftUI

/// Brief confirmation banner shown after a thought is saved.
struct SavedToast: View {
    let folderName: String
    let colorName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(FolderColor.from(name: colorName))
            Text("Saved to \(folderName)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NestTheme.primaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(FolderColor.from(name: colorName).opacity(0.45), lineWidth: 1)
        )
        .shadow(color: FolderColor.from(name: colorName).opacity(0.25), radius: 12, y: 6)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
