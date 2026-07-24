import SwiftUI

/// Personal settings: app theme, sound, haptics, and onboarding reset.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(NestAppTheme.storageKey) private var themeRaw = NestAppTheme.duskPurple.rawValue
    @AppStorage(NestSettingsKeys.soundsEnabled) private var soundsEnabled = true
    @AppStorage(NestSettingsKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    private var selectedTheme: NestAppTheme {
        NestAppTheme(rawValue: themeRaw) ?? .duskPurple
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        themeSection
                        feedbackSection
                        tourSection
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(NestTheme.primaryText)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App color")
                .font(.headline)
                .foregroundStyle(NestTheme.primaryText)

            Text("Choose a calm palette for Nest.")
                .font(.subheadline)
                .foregroundStyle(NestTheme.secondaryText)

            ForEach(NestAppTheme.allCases) { theme in
                Button {
                    themeRaw = theme.rawValue
                    NestSoundPlayer.shared.play(.softPop)
                } label: {
                    HStack(spacing: 14) {
                        Circle()
                            .fill(NestTheme.accentGradient(for: theme))
                            .frame(width: 36, height: 36)
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(theme.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(NestTheme.primaryText)
                            Text(theme.subtitle)
                                .font(.caption)
                                .foregroundStyle(NestTheme.secondaryText)
                        }

                        Spacer()

                        if selectedTheme == theme {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.tabTint)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                selectedTheme == theme
                                    ? Color.white.opacity(0.14)
                                    : NestTheme.cardBackground
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feedback")
                .font(.headline)
                .foregroundStyle(NestTheme.primaryText)

            settingsToggle(
                title: "Sound effects",
                subtitle: "Soft tones in tools and on the Home bird",
                isOn: $soundsEnabled
            )

            settingsToggle(
                title: "Haptics",
                subtitle: "Gentle vibration for taps and pops",
                isOn: $hapticsEnabled
            )
        }
    }

    private var tourSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tour")
                .font(.headline)
                .foregroundStyle(NestTheme.primaryText)

            Button {
                onboardingCompleted = false
                NestSoundPlayer.shared.play(.chime)
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Replay onboarding")
                            .font(.subheadline.weight(.semibold))
                        Text("Show the first-launch tour again next time you open Nest.")
                            .font(.caption)
                            .foregroundStyle(NestTheme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "arrow.counterclockwise")
                }
                .foregroundStyle(NestTheme.primaryText)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(NestTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func settingsToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(NestTheme.primaryText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(NestTheme.secondaryText)
            }
        }
        .tint(selectedTheme.tabTint)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(NestTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                )
        )
    }
}

#Preview {
    SettingsView()
}
