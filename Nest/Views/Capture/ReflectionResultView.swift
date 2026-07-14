import SwiftUI

/// Full-screen AI reflection shown immediately after a voice journal is saved.
struct ReflectionResultView: View {
    let analysis: ReflectionAnalysis
    let savedFolderName: String?
    let savedFolderColorName: String?
    let onKeepSharing: () -> Void
    let onTakeAMoment: () -> Void
    let onDoneForNow: () -> Void

    @State private var showToast = true

    var body: some View {
        ZStack {
            NestBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Spacer(minLength: 40)

                    Text(analysis.reflection)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(NestTheme.primaryText)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .overlay(NestTheme.cardStroke)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Whenever you're ready")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(NestTheme.secondaryText)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Button(action: onKeepSharing) {
                            ReflectionChoiceRow(
                                title: "Keep sharing",
                                subtitle: "Record another voice note"
                            )
                        }
                        .buttonStyle(ReflectionChoiceStyle())

                        Button(action: onTakeAMoment) {
                            ReflectionChoiceRow(
                                title: "Take a moment",
                                subtitle: "\(analysis.recommendedTool.displayName) · \(analysis.recommendedTool.categoryLabel)"
                            )
                        }
                        .buttonStyle(ReflectionChoiceStyle())

                        Button(action: onDoneForNow) {
                            Text("I'm done for now")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(NestTheme.secondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 28)
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

#Preview {
    ReflectionResultView(
        analysis: ReflectionAnalysis(
            reflection: "It sounds like you're carrying a lot right now. You may be feeling some overwhelm — and that makes sense from what you shared.",
            stressor: "stress",
            emotion: "overwhelm",
            recommendedTool: .guidedBreathing,
            suggestedFolder: nil,
            crisis: false
        ),
        savedFolderName: "Inbox",
        savedFolderColorName: "gray",
        onKeepSharing: {},
        onTakeAMoment: {},
        onDoneForNow: {}
    )
}
