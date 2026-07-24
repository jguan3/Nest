import SwiftUI

/// Write a worry, seal it in a box, then release it from your hands.
struct WorryBoxToolView: View {
    @State private var worryText = ""
    @State private var isSealed = false
    @State private var isReleased = false
    @State private var boxScale: CGFloat = 1
    @State private var sparkle = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            NestBackground()
            ToolStageBackdrop(accent: Color(red: 0.75, green: 0.55, blue: 0.35))

            ScrollView {
                VStack(spacing: 24) {
                    Text(headerTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(NestTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(NestTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)

                    ZStack {
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(Color.white.opacity(sparkle ? 0.25 : 0.08))
                                .frame(width: 5, height: 5)
                                .offset(
                                    x: CGFloat([-70, -40, 0, 45, 70][index]),
                                    y: CGFloat([-90, -110, -120, -105, -85][index]) + (sparkle ? -8 : 0)
                                )
                                .opacity(isReleased ? 1 : 0.35)
                        }

                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.52, green: 0.36, blue: 0.24),
                                        Color(red: 0.32, green: 0.22, blue: 0.16)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 240, height: 160)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.35), radius: 18, y: 10)
                            .scaleEffect(boxScale)
                            .opacity(isReleased ? 0 : 1)
                            .offset(y: isReleased ? -200 : 0)

                        // Lid line
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 180, height: 3)
                            .offset(y: isSealed ? -48 : -58)
                            .opacity(isReleased ? 0 : 1)

                        if !isSealed {
                            TextField("What’s weighing on you?", text: $worryText, axis: .vertical)
                                .lineLimit(3...5)
                                .padding(14)
                                .frame(width: 210, height: 110, alignment: .topLeading)
                                .foregroundStyle(NestTheme.primaryText)
                                .focused($isFocused)
                        } else if !isReleased {
                            VStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.title2)
                                Text("Held safely")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(NestTheme.primaryText.opacity(0.9))
                        }
                    }
                    .frame(height: 240)
                    .animation(.easeInOut(duration: 1.8), value: isReleased)

                    if isReleased {
                        Text("You don’t have to carry that alone right now.")
                            .font(.body)
                            .foregroundStyle(NestTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    HStack(spacing: 12) {
                        if isReleased {
                            Button("New worry") { reset() }
                                .buttonStyle(NestSecondaryButtonStyle())
                        } else if isSealed {
                            Button("Release it") { releaseWorry() }
                                .buttonStyle(NestPrimaryButtonStyle())
                        } else {
                            Button("Seal in the box") { sealWorry() }
                                .buttonStyle(NestPrimaryButtonStyle())
                                .disabled(worryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                .opacity(worryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                        }
                    }
                    .padding(.bottom, 28)
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle("Worry Box")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) {
                sparkle = true
            }
        }
        .onTapGesture { isFocused = false }
    }

    private var headerTitle: String {
        if isReleased { return "Released." }
        if isSealed { return "It’s in the box for now." }
        return "Put the worry down for a moment."
    }

    private var subtitle: String {
        if isReleased { return "The thought can wait outside your body." }
        if isSealed { return "When you’re ready, let the box float away." }
        return "Naming it is enough. You don’t need to solve it yet."
    }

    private func sealWorry() {
        isFocused = false
        NestSoundPlayer.shared.play(.seal)
        NestHaptics.mediumTap()
        withAnimation(.spring(response: 0.7, dampingFraction: 0.86)) {
            isSealed = true
            boxScale = 1.05
        }
        withAnimation(.easeOut(duration: 0.55).delay(0.3)) {
            boxScale = 1
        }
    }

    private func releaseWorry() {
        NestSoundPlayer.shared.play(.release)
        NestHaptics.softTap()
        withAnimation(.easeInOut(duration: 1.8)) {
            isReleased = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            worryText = ""
        }
    }

    private func reset() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.88)) {
            isSealed = false
            isReleased = false
            boxScale = 1
            worryText = ""
        }
    }
}

#Preview {
    NavigationStack {
        WorryBoxToolView()
    }
}
