import SwiftUI

/// Primary call-to-action to begin voice capture.
struct EmptyThoughtsButton: View {
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Empty your thoughts")
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
    }
}

/// Ends an active recording session.
struct StopRecordingButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                Text("Stop")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.28, blue: 0.38),
                                Color(red: 0.78, green: 0.18, blue: 0.42)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.red.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color.red.opacity(0.45), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop recording")
    }
}
