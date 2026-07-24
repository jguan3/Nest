import SwiftData
import SwiftUI

/// Personal tab showing profile level and mood reflection history.
struct PersonalView: View {
    let activeOnboardingHighlight: OnboardingHighlight?

    @Query(sort: \MoodEntry.createdAt, order: .reverse) private var moodEntries: [MoodEntry]
    @AppStorage(XPStore.totalXPKey) private var totalXP = 0
    @AppStorage(ProfileAvatarStore.iconKey) private var avatarIconRaw = ProfileAvatarIcon.person.rawValue
    @AppStorage(ProfileAvatarStore.colorKey) private var avatarColorRaw = ProfileAvatarColor.lilac.rawValue
    @State private var isAvatarPickerPresented = false
    @State private var isSettingsPresented = false

    private let placeholderLevel = 1
    private let placeholderBirdName = "Nestling"
    private let xpToNextLevel = XPStore.xpToNextLevel

    private var latestTodayMood: MoodOption? {
        MoodStore.latestToday(from: moodEntries)
    }

    private var avatarIcon: ProfileAvatarIcon {
        ProfileAvatarIcon(rawValue: avatarIconRaw) ?? .person
    }

    private var avatarColor: ProfileAvatarColor {
        ProfileAvatarColor(rawValue: avatarColorRaw) ?? .lilac
    }

    init(activeOnboardingHighlight: OnboardingHighlight? = nil) {
        self.activeOnboardingHighlight = activeOnboardingHighlight
    }

    var body: some View {
        ZStack {
            NestBackground()

            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        HStack(alignment: .center) {
                            Text("Personal")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(NestTheme.primaryText)

                            Spacer()

                            Button {
                                isSettingsPresented = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(NestTheme.primaryText)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(NestTheme.cardBackground)
                                            .overlay(Circle().strokeBorder(NestTheme.cardStroke, lineWidth: 1))
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Settings")
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        profileCard

                        todaysLandingCard

                        MoodHistorySection(moodEntries: moodEntries)
                            .onboardingAnchor(.history)
                            .id(OnboardingHighlight.history)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                    }
                }
                .onChange(of: activeOnboardingHighlight) { _, highlight in
                    guard highlight == .history else { return }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                        scrollProxy.scrollTo(OnboardingHighlight.history, anchor: .bottom)
                    }
                }
            }
        }
        .sheet(isPresented: $isAvatarPickerPresented) {
            ProfileAvatarPickerSheet(
                selectedIcon: $avatarIconRaw,
                selectedColor: $avatarColorRaw
            )
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
        }
    }

    /// Fill amount for the XP bar, clamped so it never overflows the track.
    private var progress: CGFloat {
        min(1, CGFloat(totalXP) / CGFloat(max(xpToNextLevel, 1)))
    }

    private var profileCard: some View {
        VStack(spacing: 18) {
            Button {
                isAvatarPickerPresented = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    ProfileAvatarView(size: 110, icon: avatarIcon, color: avatarColor)

                    Image(systemName: "paintpalette.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white)
                        .padding(8)
                        .background(Circle().fill(NestTheme.accentGradient))
                        .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose profile look")
            .accessibilityHint("Opens the built-in avatar and color library")

            Text("Tap to choose a look")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NestTheme.secondaryText)

            Text("Level \(placeholderLevel)")
                .font(.title.weight(.bold))
                .foregroundStyle(NestTheme.primaryText)

            Text(placeholderBirdName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NestTheme.secondaryText)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("XP")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NestTheme.secondaryText)
                    Spacer()
                    Text("\(totalXP) / \(xpToNextLevel)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NestTheme.secondaryText)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(NestTheme.accentGradient)
                            .frame(width: max(8, geometry.size.width * progress))
                            .animation(.easeInOut(duration: 0.45), value: totalXP)
                    }
                }
                .frame(height: 10)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Text("Leveling comes soon. Keep checking in on \(placeholderBirdName) for now.")
                .font(.footnote)
                .foregroundStyle(NestTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(NestTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }

    private var todaysLandingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today’s landing")
                .font(.headline)
                .foregroundStyle(NestTheme.primaryText)

            if let todayMood = latestTodayMood {
                HStack(spacing: 12) {
                    MoodSymbolView(mood: todayMood, font: .title3)
                    Text(todayMood.label)
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(NestTheme.primaryText)

                Text(todayMood.response)
                    .font(.footnote)
                    .foregroundStyle(NestTheme.secondaryText)
            } else {
                Text("Check in on Home when you’re ready.")
                    .font(.subheadline)
                    .foregroundStyle(NestTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(NestTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
}

#Preview {
    PersonalView()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
