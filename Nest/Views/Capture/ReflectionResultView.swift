import SwiftUI

/// Full-screen companion reflection after the user shares a thought.
struct ReflectionResultView: View {
    let conversation: ReflectionConversation
    let savedFolderName: String?
    let savedFolderColorName: String?
    let onContinueReflecting: () -> Void
    let onDoneForNow: () -> Void
    let onSelectActivity: (CopingTool) -> Void
    let onDismissClosing: () -> Void

    @State private var showToast = true

    var body: some View {
        ZStack {
            NestBackground()

            switch conversation.phase {
            case .showingTurn(let turn):
                turnContent(turn)
            case .awaitingContinueInput:
                EmptyView()
            case .showingClosing(let closing):
                closingContent(closing)
            }

            if showToast,
               let savedFolderName,
               let savedFolderColorName {
                VStack {
                    SavedToast(folderName: savedFolderName, colorName: savedFolderColorName)
                        .padding(.top, 12)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    Task {
                        try? await Task.sleep(for: .seconds(3))
                        withAnimation(.spring(response: 0.4)) {
                            showToast = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - Turn

    @ViewBuilder
    private func turnContent(_ turn: ReflectionTurn) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Spacer(minLength: 40)

                Text(conversation.sourceLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NestTheme.secondaryText.opacity(0.85))

                Text(turn.reflection)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(NestTheme.primaryText)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                let latestUserText = conversation.history
                    .last(where: { $0.role == .user })?
                    .text ?? ""
                let displayThemeNotes = ActivitySuggestionHelper.sanitizeThemeNotes(
                    turn.themeNotes,
                    userText: latestUserText
                )
                if !displayThemeNotes.isEmpty {
                    FlowThemeNotes(notes: displayThemeNotes)
                }

                if let followUp = turn.followUpQuestion, !followUp.isEmpty {
                    Text(followUp)
                        .font(.body)
                        .foregroundStyle(NestTheme.secondaryText)
                        .lineSpacing(4)
                        .padding(.top, 4)
                }

                Divider()
                    .overlay(NestTheme.cardStroke)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Whenever you're ready")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NestTheme.secondaryText)
                        .textCase(.uppercase)
                        .tracking(0.6)

                    Button(action: onContinueReflecting) {
                        ReflectionChoiceRow(
                            title: "Continue reflecting",
                            subtitle: "Share more by voice or text — only if you want to"
                        )
                    }
                    .buttonStyle(ReflectionChoiceStyle())

                    Button(action: onDoneForNow) {
                        Text("Explore a calming exercise")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(NestTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    .accessibilityHint("See a few gentle exercises that might help you unwind")

                    Button(action: onDismissClosing) {
                        Text("I'm done for now")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(NestTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .accessibilityHint("Leave this reflection and return to Nest")
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Closing

    @ViewBuilder
    private func closingContent(_ closing: ReflectionClosing) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Spacer(minLength: 40)

                Text(conversation.sourceLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NestTheme.secondaryText.opacity(0.85))

                Text(closing.summary)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(NestTheme.primaryText)
                    .lineSpacing(6)

                Divider()
                    .overlay(NestTheme.cardStroke)

                Text(closing.invitationLine)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(NestTheme.secondaryText)

                VStack(spacing: 12) {
                    ForEach(closing.suggestedActivities) { tool in
                        Button {
                            onSelectActivity(tool)
                        } label: {
                            ReflectionChoiceRow(
                                title: tool.displayName,
                                subtitle: "\(tool.categoryLabel) · \(tool.subtitle)"
                            )
                        }
                        .buttonStyle(ReflectionChoiceStyle())
                    }
                }

                Button(action: onDismissClosing) {
                    Text("Maybe later")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(NestTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 28)
        }
    }
}

private struct FlowThemeNotes: View {
    let notes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What Nest noticed")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NestTheme.secondaryText)
                .textCase(.uppercase)
                .tracking(0.6)

            ForEach(notes, id: \.self) { note in
                Text(note)
                    .font(.subheadline)
                    .foregroundStyle(NestTheme.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(NestTheme.cardBackground)
                            .overlay(Capsule().strokeBorder(NestTheme.cardStroke, lineWidth: 1))
                    )
            }
        }
    }
}

private struct ReflectionChoiceRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(NestTheme.primaryText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(NestTheme.secondaryText)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NestTheme.secondaryText.opacity(0.8))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ReflectionChoiceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(NestTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                    )
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

#Preview("Turn") {
    ReflectionResultView(
        conversation: ReflectionConversation(
            phase: .showingTurn(
                ReflectionTurn(
                    reflection: "It sounds like school may be weighing on you right now. From what you shared, you might be carrying a sense of pressure — and that makes sense.",
                    themeNotes: ["a sense of overwhelm", "pressure around school"],
                    followUpQuestion: "If you could hold just one piece of school today, which would it be?",
                    feelsNaturalPause: false,
                    crisisKind: .none,
                    recommendedTool: .focusBubble,
                    stressor: "school",
                    emotion: "a sense of overwhelm",
                    title: "School Pressure",
                    preview: "Feeling weighed down by school and a sense of pressure."
                )
            ),
            history: [],
            sourceLabel: "Offline Nest assistant"
        ),
        savedFolderName: "Inbox",
        savedFolderColorName: "gray",
        onContinueReflecting: {},
        onDoneForNow: {},
        onSelectActivity: { _ in },
        onDismissClosing: {}
    )
}

#Preview("Closing") {
    ReflectionResultView(
        conversation: ReflectionConversation(
            phase: .showingClosing(
                ReflectionClosing(
                    summary: "From what you shared, it seems like school has been on your mind, and you might be carrying a sense of overwhelm.",
                    invitationLine: ReflectionClosing.defaultInvitationLine,
                    suggestedActivities: [.focusBubble, .worryBox, .guidedBreathing]
                )
            ),
            history: [],
            sourceLabel: "On-device Nest"
        ),
        savedFolderName: "Inbox",
        savedFolderColorName: "gray",
        onContinueReflecting: {},
        onDoneForNow: {},
        onSelectActivity: { _ in },
        onDismissClosing: {}
    )
}
