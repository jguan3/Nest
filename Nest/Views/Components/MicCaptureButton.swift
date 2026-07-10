import SwiftUI

/// Large circular microphone button with capture state visuals.
struct MicCaptureButton: View {
    let state: CaptureState
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if state == .listening {
                    Circle()
                        .stroke(Color.red.opacity(0.25), lineWidth: 2)
                        .frame(width: 156, height: 156)
                        .scaleEffect(isPulsing ? 1.06 : 0.94)
                        .animation(
                            .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                            value: isPulsing
                        )

                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 148, height: 148)
                        .scaleEffect(isPulsing ? 1.04 : 0.96)
                        .animation(
                            .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                }

                Circle()
                    .fill(buttonGradient)
                    .frame(width: 120, height: 120)
                    .shadow(color: shadowColor.opacity(0.45), radius: 20, y: 10)

                Circle()
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    .frame(width: 120, height: 120)

                Image(systemName: iconName)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, isActive: state == .listening)
            }
        }
        .buttonStyle(.plain)
        .disabled(state == .processing)
        .onAppear { isPulsing = state == .listening }
        .onChange(of: state) { _, newState in
            isPulsing = newState == .listening
        }
    }

    private var buttonGradient: LinearGradient {
        switch state {
        case .listening:
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.35, blue: 0.38), Color(red: 0.92, green: 0.22, blue: 0.34)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .processing:
            LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .top, endPoint: .bottom)
        default:
            NestTheme.accentGradient
        }
    }

    private var shadowColor: Color {
        state == .listening ? .red : Color(red: 0.45, green: 0.55, blue: 1.0)
    }

    private var iconName: String {
        switch state {
        case .listening: "stop.fill"
        case .processing: "ellipsis"
        default: "mic.fill"
        }
    }
}
