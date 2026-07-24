import SwiftUI

/// Write a short kind note to yourself and keep it on screen.
struct KindNoteToolView: View {
    @State private var note = ""
    @State private var savedNote: String?
    @State private var floatHeart = false
    @FocusState private var isFocused: Bool
    @AppStorage("nest.kindNote.saved") private var persistedNote = ""

    private let prompts = [
        "You’re allowed to go slowly.",
        "This feeling will move.",
        "You did what you could today.",
        "Soft is still strong."
    ]

    var body: some View {
        ZStack {
            NestBackground()
            ToolStageBackdrop(accent: Color(red: 0.95, green: 0.5, blue: 0.65))

            ScrollView {
                VStack(spacing: 22) {
                    ZStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.55, blue: 0.7),
                                        Color(red: 0.75, green: 0.45, blue: 0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(floatHeart ? 1.08 : 0.95)
                            .opacity(0.9)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .offset(x: floatHeart ? 50 : 40, y: floatHeart ? -36 : -28)
                    }
                    .frame(height: 90)

                    Text("What would you say to a friend feeling like this?")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(NestTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Text("Now say that to yourself.")
                        .font(.subheadline)
                        .foregroundStyle(NestTheme.secondaryText)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(prompts, id: \.self) { prompt in
                                Button {
                                    note = prompt
                                } label: {
                                    Text(prompt)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(NestTheme.primaryText)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(NestTheme.cardBackground)
                                                .overlay(Capsule().strokeBorder(NestTheme.cardStroke, lineWidth: 1))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    TextField("Write something gentle…", text: $note, axis: .vertical)
                        .lineLimit(4...8)
                        .padding(16)
                        .foregroundStyle(NestTheme.primaryText)
                        .focused($isFocused)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(NestTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)

                    Button("Keep this note") {
                        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        isFocused = false
                        NestSoundPlayer.shared.play(.sparkle)
                        NestHaptics.softTap()
                        withAnimation {
                            savedNote = trimmed
                            persistedNote = trimmed
                        }
                    }
                    .buttonStyle(NestPrimaryButtonStyle())
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)

                    if let savedNote, !savedNote.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("A note for you", systemImage: "seal.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(NestTheme.secondaryText)
                            Text(savedNote)
                                .font(.body.weight(.medium))
                                .foregroundStyle(NestTheme.primaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.12),
                                            Color(red: 0.85, green: 0.45, blue: 0.7).opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer(minLength: 24)
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle("Kind Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            if !persistedNote.isEmpty { savedNote = persistedNote }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                floatHeart = true
            }
        }
        .onTapGesture { isFocused = false }
    }
}

#Preview {
    NavigationStack {
        KindNoteToolView()
    }
}
