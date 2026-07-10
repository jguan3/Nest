import SwiftUI

/// Shared visual styling for Nest screens.
enum NestTheme {
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.16, green: 0.10, blue: 0.30),
            Color(red: 0.22, green: 0.14, blue: 0.40),
            Color(red: 0.12, green: 0.16, blue: 0.34)
        ],
        startPoint: .top,
        endPoint: .bottom
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

/// Ambient animated background used across Nest screens.
struct NestBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            NestTheme.backgroundGradient
                .ignoresSafeArea()

            Circle()
                .fill(Color.purple.opacity(0.28))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: drift ? -90 : -130, y: drift ? -200 : -240)

            Circle()
                .fill(Color.blue.opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 55)
                .offset(x: drift ? 150 : 120, y: drift ? 200 : 160)

            Circle()
                .fill(Color(red: 0.85, green: 0.45, blue: 0.75).opacity(0.12))
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .offset(x: drift ? 40 : -20, y: drift ? 80 : 120)

            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.08 + Double(index % 3) * 0.03))
                    .frame(width: CGFloat(2 + index % 3), height: CGFloat(2 + index % 3))
                    .offset(
                        x: CGFloat((index * 37) % 280) - 140,
                        y: CGFloat((index * 53) % 500) - 220 + (drift ? 12 : -8)
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

/// Decorative stage used inside tools so screens feel less empty.
struct ToolStageBackdrop: View {
    var accent: Color = Color(red: 0.65, green: 0.55, blue: 1.0)

    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .scaleEffect(pulse ? 1.08 : 0.92)

            Circle()
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 240, height: 240)

            Circle()
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                .frame(width: 300, height: 300)
                .scaleEffect(pulse ? 1.05 : 0.98)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

/// Shared primary capsule button for tools.
struct NestPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(Capsule().fill(NestTheme.accentGradient))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Shared secondary capsule button for tools.
struct NestSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(NestTheme.primaryText)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(NestTheme.cardBackground)
                    .overlay(Capsule().strokeBorder(NestTheme.cardStroke, lineWidth: 1))
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
