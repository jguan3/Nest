import SwiftUI

/// Renders a mood’s weather icon. Calm is a soft sun with a breeze overlay
/// because SF Symbols has no single sun-and-breeze glyph.
struct MoodSymbolView: View {
    let mood: MoodOption
    var font: Font = .body

    var body: some View {
        Group {
            if mood == .calm {
                ZStack {
                    Image(systemName: "sun.min.fill")
                    Image(systemName: "wind")
                        .scaleEffect(0.48)
                        .offset(x: 5, y: 6)
                }
            } else {
                Image(systemName: mood.symbol)
            }
        }
        .font(font)
        .accessibilityHidden(true)
    }
}
