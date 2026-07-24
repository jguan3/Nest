import SwiftUI

/// Tools hub listing grounding and focus utilities, with favorites pinned at the top.
struct ToolsView: View {
    @Binding var pendingTool: CopingTool?
    @AppStorage(FavoriteToolsStore.storageKey) private var favoritesRaw = ""

    private let sectionOrder = [
        "Calm the body",
        "Come back to now",
        "Hold one thing",
        "Play softly"
    ]

    init(pendingTool: Binding<CopingTool?> = .constant(nil)) {
        _pendingTool = pendingTool
    }

    private var favoriteTools: [CopingTool] {
        FavoriteToolsStore.tools(from: favoritesRaw)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tools")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(NestTheme.primaryText)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                        Text("Small resets when your mind needs an anchor.")
                            .font(.subheadline)
                            .foregroundStyle(NestTheme.secondaryText)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 4)

                        if !favoriteTools.isEmpty {
                            toolSection("Favorites")
                            ForEach(Array(favoriteTools.enumerated()), id: \.element.id) { index, tool in
                                toolLink(tool, isFirstOnboardingAnchor: index == 0)
                            }
                        }

                        ForEach(sectionOrder, id: \.self) { section in
                            let tools = CopingTool.allCases.filter {
                                $0.categoryLabel == section && !favoriteTools.contains($0)
                            }
                            if !tools.isEmpty {
                                toolSection(section)
                                ForEach(Array(tools.enumerated()), id: \.element.id) { index, tool in
                                    toolLink(
                                        tool,
                                        isFirstOnboardingAnchor: favoriteTools.isEmpty
                                            && section == "Calm the body"
                                            && index == 0
                                    )
                                }
                            }
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $pendingTool) { tool in
                destination(for: tool)
            }
        }
    }

    private func toolLink(_ tool: CopingTool, isFirstOnboardingAnchor: Bool) -> some View {
        HStack(spacing: 4) {
            NavigationLink {
                destination(for: tool)
            } label: {
                ToolCard(tool: tool)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    favoritesRaw = FavoriteToolsStore.toggling(tool, in: favoritesRaw)
                }
            } label: {
                Image(systemName: FavoriteToolsStore.contains(tool, in: favoritesRaw) ? "star.fill" : "star")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(
                        FavoriteToolsStore.contains(tool, in: favoritesRaw)
                            ? Color(red: 1.0, green: 0.82, blue: 0.4)
                            : NestTheme.secondaryText
                    )
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                FavoriteToolsStore.contains(tool, in: favoritesRaw)
                    ? "Remove from favorites"
                    : "Add to favorites"
            )
        }
        .padding(.trailing, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(NestTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .modifier(OptionalOnboardingAnchor(isActive: isFirstOnboardingAnchor))
    }

    @ViewBuilder
    private func destination(for tool: CopingTool) -> some View {
        switch tool {
        case .guidedBreathing: BreathingToolView()
        case .softUnwind: SoftUnwindToolView()
        case .softFocusBeats: SoftFocusBeatsToolView()
        case .colorGrounding: ColorGroundingToolView()
        case .ripplePond: RipplePondToolView()
        case .focusBubble: FocusToolView()
        case .worryBox: WorryBoxToolView()
        case .bubbleDrift: BubbleDriftToolView()
        case .kindNote: KindNoteToolView()
        }
    }

    private func toolSection(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.bold))
            .tracking(0.8)
            .foregroundStyle(NestTheme.secondaryText)
            .padding(.horizontal, 24)
            .padding(.top, 10)
    }
}

/// Applies the wellness-tools onboarding anchor only when requested.
private struct OptionalOnboardingAnchor: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content.onboardingAnchor(.wellnessTools)
        } else {
            content
        }
    }
}

/// Card row for a single tool in the Tools hub.
private struct ToolCard: View {
    let tool: CopingTool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tool.tint.opacity(0.22))
                    .frame(width: 48, height: 48)
                Image(systemName: tool.systemImage)
                    .font(.title3)
                    .foregroundStyle(tool.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.displayName)
                    .font(.headline)
                    .foregroundStyle(NestTheme.primaryText)
                Text(tool.subtitle)
                    .font(.caption)
                    .foregroundStyle(NestTheme.secondaryText)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NestTheme.secondaryText)
        }
        .padding(.leading, 16)
        .padding(.vertical, 16)
        .padding(.trailing, 4)
    }
}

#Preview {
    ToolsView()
}
