import SwiftUI

/// Shared visual styling for Nest screens.
enum NestTheme {
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.07, green: 0.08, blue: 0.16),
            Color(red: 0.12, green: 0.10, blue: 0.22),
            Color(red: 0.08, green: 0.12, blue: 0.20)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.45, green: 0.55, blue: 1.0), Color(red: 0.65, green: 0.45, blue: 0.98)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardBackground = Color.white.opacity(0.08)
    static let cardStroke = Color.white.opacity(0.12)
    static let secondaryText = Color.white.opacity(0.55)
    static let primaryText = Color.white.opacity(0.95)
}

/// Ambient gradient background used across Nest screens.
struct NestBackground: View {
    var body: some View {
        ZStack {
            NestTheme.backgroundGradient
                .ignoresSafeArea()

            Circle()
                .fill(Color.purple.opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: -120, y: -220)

            Circle()
                .fill(Color.blue.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(x: 140, y: 180)
        }
    }
}
