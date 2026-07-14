import SwiftUI

/// Supportive crisis resources shown when self-harm language is detected.
struct CrisisSupportView: View {
    let savedFolderName: String?
    let savedFolderColorName: String?
    let onDismiss: () -> Void

    @State private var showToast = true

    var body: some View {
        ZStack {
            NestBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Spacer(minLength: 48)

                    Text("Thank you for sharing")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(NestTheme.primaryText)

                    Text("What you shared sounds really heavy. You deserve support right now — you don't have to carry this alone.")
                        .font(.body)
                        .foregroundStyle(NestTheme.primaryText.opacity(0.9))
                        .lineSpacing(5)

                    VStack(spacing: 14) {
                        crisisLink(
                            title: "988 Suicide & Crisis Lifeline",
                            subtitle: "Call or text 988 — free, 24/7",
                            url: URL(string: "tel:988")!
                        )
                        crisisLink(
                            title: "Crisis Text Line",
                            subtitle: "Text HOME to 741741",
                            url: URL(string: "sms:741741&body=HOME")!
                        )
                    }

                    Text("These are trained counselors who want to listen. Reaching out is a sign of strength.")
                        .font(.footnote)
                        .foregroundStyle(NestTheme.secondaryText)
                        .padding(.top, 4)

                    Button(action: onDismiss) {
                        Text("I'm safe for now")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(NestSecondaryButtonStyle())
                    .padding(.top, 12)

                    Spacer(minLength: 48)
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

    private func crisisLink(title: String, subtitle: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 14) {
                Image(systemName: "phone.fill")
                    .font(.title3)
                    .foregroundStyle(Color(red: 0.55, green: 0.75, blue: 1.0))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(red: 0.55, green: 0.75, blue: 1.0).opacity(0.18))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(NestTheme.primaryText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(NestTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NestTheme.secondaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(NestTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    CrisisSupportView(savedFolderName: "Inbox", savedFolderColorName: "gray", onDismiss: {})
}
