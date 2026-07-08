import SwiftUI

/// A small colored dot representing a folder's preset color.
struct FolderColorDot: View {
    let colorName: String
    var size: CGFloat = 12

    var body: some View {
        Circle()
            .fill(FolderColor.gradient(for: colorName))
            .frame(width: size, height: size)
    }
}
