import SwiftUI

/// De-escalation guidance shown when violent intent toward others is detected.
///
/// This path deliberately avoids the suicide prevention hotline and instead
/// focuses on creating distance, calming steps, trusted support, and emergency
/// services when there is immediate risk of acting.
struct HarmToOthersSupportView: View {
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

                    Text("Pause with this feeling")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(NestTheme.primaryText)

                    Text("I’m sorry you’re dealing with such intense feelings right now. You don’t have to act on them — taking a moment to slow down can help keep you and others safer.")
                        .font(.body)
                        .foregroundStyle(NestTheme.primaryText.opacity(0.9))
                        .lineSpacing(5)

                    guidanceCard(
                        title: "Check in with yourself",
                        detail: "Are you in immediate danger of acting on these thoughts? Naming that honestly is a first step toward staying safe."
                    )

                    guidanceCard(
                        title: "Create some distance",
                        detail: "If you can, step away from the person, place, object, or situation connected to the urge to harm someone."
                    )

                    guidanceCard(
                        title: "Try a brief calm-down step",
                        detail: "Slow breathing, stepping outside, drinking water, washing your face with cold water, or taking a short walk can help intensity ease."
                    )

                    guidanceCard(
                        title: "Reach out for support",
                        detail: "Contact a trusted person who can help you calm down and stay safe. If these thoughts keep returning or feel hard to control, seek support from a mental health professional soon."
                    )

                    VStack(spacing: 14) {
                        crisisLink(
                            title: "Emergency services",
                            subtitle: "If you may act now or can’t keep others safe — call 911",
                            systemImage: "phone.fill",
                            url: URL(string: "tel:911")!
                        )
                    }

                    Text("If you might act right away, leave the situation if you can and contact local emergency services or another immediate crisis resource.")
                        .font(.footnote)
                        .foregroundStyle(NestTheme.secondaryText)
                        .padding(.top, 4)

                    Button(action: onDismiss) {
                        Text("I’m safer for now")
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

    /// Builds a calm guidance block for a single de-escalation step.
    /// - Parameters:
    ///   - title: Short step heading.
    ///   - detail: Supportive explanation of what to try.
    /// - Returns: Styled guidance card view.
    private func guidanceCard(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(NestTheme.primaryText)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(NestTheme.secondaryText)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    /// Builds a tappable emergency resource row.
    /// - Parameters:
    ///   - title: Resource name.
    ///   - subtitle: Short call-to-action description.
    ///   - systemImage: SF Symbol for the leading icon.
    ///   - url: Destination URL (usually a tel: link).
    /// - Returns: Styled link row.
    private func crisisLink(title: String, subtitle: String, systemImage: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.45))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(red: 1.0, green: 0.55, blue: 0.45).opacity(0.18))
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
    HarmToOthersSupportView(savedFolderName: "Inbox", savedFolderColorName: "gray", onDismiss: {})
}
