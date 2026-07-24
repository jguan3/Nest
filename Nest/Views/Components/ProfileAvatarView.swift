import SwiftUI

/// Circular profile avatar from the built-in icon + color library.
struct ProfileAvatarView: View {
    var size: CGFloat = 44
    var icon: ProfileAvatarIcon = .person
    var color: ProfileAvatarColor = .lilac

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            color.color.opacity(0.95),
                            color.color.opacity(0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: icon.systemImage)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.95))
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(Color.white.opacity(0.22), lineWidth: 1))
        .accessibilityLabel("Profile picture")
    }
}

/// Compact peach bird avatar for conversational reflection UI.
struct NestBirdAvatarView: View {
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.82, blue: 0.58).opacity(0.35),
                            NestTheme.cardBackground
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(Circle().strokeBorder(NestTheme.cardStroke, lineWidth: 1))

            CuteNestBird(scale: size / 115, facingRight: true)
                .offset(y: size * 0.08)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("Nest bird")
    }
}

/// Sheet for choosing a built-in avatar icon and color.
struct ProfileAvatarPickerSheet: View {
    @Binding var selectedIcon: String
    @Binding var selectedColor: String
    @Environment(\.dismiss) private var dismiss

    private var icon: ProfileAvatarIcon {
        ProfileAvatarIcon(rawValue: selectedIcon) ?? .person
    }

    private var color: ProfileAvatarColor {
        ProfileAvatarColor(rawValue: selectedColor) ?? .lilac
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        ProfileAvatarView(size: 96, icon: icon, color: color)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Picture")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(NestTheme.secondaryText)

                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                                spacing: 12
                            ) {
                                ForEach(ProfileAvatarIcon.allCases) { option in
                                    Button {
                                        selectedIcon = option.rawValue
                                        NestSoundPlayer.shared.play(.softPop)
                                    } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(
                                                    icon == option
                                                        ? Color.white.opacity(0.18)
                                                        : NestTheme.cardBackground
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .strokeBorder(
                                                            icon == option
                                                                ? Color.white.opacity(0.35)
                                                                : NestTheme.cardStroke,
                                                            lineWidth: 1
                                                        )
                                                )

                                            Image(systemName: option.systemImage)
                                                .font(.title3)
                                                .foregroundStyle(NestTheme.primaryText)
                                        }
                                        .frame(height: 58)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(option.title)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(NestTheme.secondaryText)

                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                                spacing: 12
                            ) {
                                ForEach(ProfileAvatarColor.allCases) { option in
                                    Button {
                                        selectedColor = option.rawValue
                                        NestSoundPlayer.shared.play(.sparkle)
                                    } label: {
                                        Circle()
                                            .fill(option.color)
                                            .frame(height: 44)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(
                                                        color == option
                                                            ? Color.white
                                                            : Color.white.opacity(0.2),
                                                        lineWidth: color == option ? 3 : 1
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(option.title)
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Profile look")
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
}
