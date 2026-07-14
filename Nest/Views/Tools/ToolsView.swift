import SwiftUI

/// Tools hub listing grounding and focus utilities.
struct ToolsView: View {
    @Binding var pendingTool: CopingTool?

    init(pendingTool: Binding<CopingTool?> = .constant(nil)) {
        _pendingTool = pendingTool
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

                        // Soft section labels to break up the list
                        toolSection("Calm the body")
                        NavigationLink {
                            BreathingToolView()
                        } label: {
                            ToolCard(
                                title: "Guided Breathing",
                                subtitle: "Inhale and exhale with a calm expanding circle",
                                systemImage: "wind",
                                tint: Color(red: 0.55, green: 0.7, blue: 1.0)
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SoftUnwindToolView()
                        } label: {
                            ToolCard(
                                title: "Soft Unwind",
                                subtitle: "A gentle body check-in for releasing tension",
                                systemImage: "figure.mind.and.body",
                                tint: Color(red: 0.55, green: 0.85, blue: 0.65)
                            )
                        }
                        .buttonStyle(.plain)

                        toolSection("Come back to now")
                        NavigationLink {
                            ColorGroundingToolView()
                        } label: {
                            ToolCard(
                                title: "Color Grounding",
                                subtitle: "Find something that matches a random niche color",
                                systemImage: "eyedropper.halffull",
                                tint: Color(red: 0.95, green: 0.65, blue: 0.45)
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            RipplePondToolView()
                        } label: {
                            ToolCard(
                                title: "Ripple Pond",
                                subtitle: "Tap the water and watch soft ripples fade",
                                systemImage: "water.waves",
                                tint: Color(red: 0.45, green: 0.7, blue: 0.9)
                            )
                        }
                        .buttonStyle(.plain)

                        toolSection("Hold one thing")
                        NavigationLink {
                            FocusToolView()
                        } label: {
                            ToolCard(
                                title: "Focus Bubble",
                                subtitle: "A quiet timer to hold one task at a time",
                                systemImage: "circle.dotted",
                                tint: Color(red: 0.7, green: 0.55, blue: 1.0)
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            WorryBoxToolView()
                        } label: {
                            ToolCard(
                                title: "Worry Box",
                                subtitle: "Write a worry, seal it, then release it",
                                systemImage: "archivebox.fill",
                                tint: Color(red: 0.8, green: 0.6, blue: 0.4)
                            )
                        }
                        .buttonStyle(.plain)

                        toolSection("Play softly")
                        NavigationLink {
                            BubbleDriftToolView()
                        } label: {
                            ToolCard(
                                title: "Bubble Drift",
                                subtitle: "A chill game — soft bubbles, no pressure",
                                systemImage: "bubbles.and.sparkles",
                                tint: Color(red: 0.75, green: 0.6, blue: 1.0)
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            KindNoteToolView()
                        } label: {
                            ToolCard(
                                title: "Kind Note",
                                subtitle: "Write yourself the words you’d give a friend",
                                systemImage: "heart.text.square.fill",
                                tint: Color(red: 1.0, green: 0.55, blue: 0.7)
                            )
                        }
                        .buttonStyle(.plain)
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

    @ViewBuilder
    private func destination(for tool: CopingTool) -> some View {
        switch tool {
        case .guidedBreathing: BreathingToolView()
        case .softUnwind: SoftUnwindToolView()
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

/// Card row for a single tool in the Tools hub.
private struct ToolCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = Color(red: 0.72, green: 0.55, blue: 1.0)

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(0.22))
                    .frame(width: 48, height: 48)
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
            }

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
        .padding(.horizontal, 20)
    }
}

#Preview {
    ToolsView()
}
