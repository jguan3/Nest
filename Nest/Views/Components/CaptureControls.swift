import SwiftUI

/// Primary call-to-action to begin voice capture.
struct EmptyThoughtsButton: View {
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("empty your thoughts")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(NestTheme.accentGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: Color(red: 0.45, green: 0.55, blue: 1.0).opacity(0.35), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
        .padding(.horizontal, 20)
    }
}

/// Ends an active recording session.
struct StopRecordingButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("stop")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 120, height: 48)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.35, blue: 0.38),
                                    Color(red: 0.92, green: 0.22, blue: 0.34)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop recording")
    }
}
