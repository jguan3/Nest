import SwiftUI

/// Personal tab showing profile level and today's mood.
struct PersonalView: View {
    private let placeholderLevel = 1
    private let placeholderXP = 0
    private let xpToNextLevel = 100
    private var todayMood: MoodOption? { MoodStore.todayMood() }

    var body: some View {
        ZStack {
            NestBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Text("Personal")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(NestTheme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(NestTheme.cardBackground)
                                .frame(width: 110, height: 110)
                                .overlay(Circle().strokeBorder(NestTheme.cardStroke, lineWidth: 1))

                            Image(systemName: "person.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(NestTheme.primaryText.opacity(0.9))
                        }

                        Text("Level \(placeholderLevel)")
                            .font(.title.weight(.bold))
                            .foregroundStyle(NestTheme.primaryText)

                        Text("Nestling")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(NestTheme.secondaryText)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("XP")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(NestTheme.secondaryText)
                                Spacer()
                                Text("\(placeholderXP) / \(xpToNextLevel)")
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
                                }
                            }
                            .frame(height: 10)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                        Text("Leveling comes soon. Keep catching thoughts for now.")
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

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today’s landing")
                            .font(.headline)
                            .foregroundStyle(NestTheme.primaryText)

                        if let todayMood {
                            HStack(spacing: 12) {
                                Image(systemName: todayMood.symbol)
                                    .font(.title3)
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
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var progress: CGFloat {
        CGFloat(placeholderXP) / CGFloat(max(xpToNextLevel, 1))
    }
}

#Preview {
    PersonalView()
}
