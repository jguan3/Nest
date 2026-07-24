import SwiftUI

/// Collects feature frames in the root onboarding coordinate space.
private struct OnboardingFramePreferenceKey: PreferenceKey {
    static var defaultValue: [OnboardingHighlight: CGRect] = [:]

    static func reduce(
        value: inout [OnboardingHighlight: CGRect],
        nextValue: () -> [OnboardingHighlight: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

extension View {
    /// Publishes this view's frame so the onboarding overlay can spotlight it.
    /// - Parameter highlight: The feature represented by this view.
    /// - Returns: The view with geometry reporting attached.
    func onboardingAnchor(_ highlight: OnboardingHighlight) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: OnboardingFramePreferenceKey.self,
                    value: [highlight: geometry.frame(in: .named("onboarding"))]
                )
            }
        }
    }

    /// Observes all currently rendered onboarding feature frames.
    /// - Parameter frames: A binding updated as feature geometry changes.
    /// - Returns: The view with onboarding frame observation attached.
    func collectOnboardingFrames(
        _ frames: Binding<[OnboardingHighlight: CGRect]>
    ) -> some View {
        onPreferenceChange(OnboardingFramePreferenceKey.self) { frames.wrappedValue = $0 }
    }
}

/// A reusable, blocking spotlight tour presented above the app interface.
struct OnboardingOverlay: View {
    let steps: [OnboardingStep]
    @Binding var currentStepIndex: Int
    let highlightFrames: [OnboardingHighlight: CGRect]
    let onSkip: () -> Void
    let onFinish: () -> Void

    private let spotlightPadding: CGFloat = 8
    private let spotlightCornerRadius: CGFloat = 24
    private let estimatedCardHeight: CGFloat = 270

    private var currentStep: OnboardingStep {
        steps[currentStepIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                dimmingLayer(in: geometry.size)
                    .allowsHitTesting(false)

                if let spotlightFrame {
                    spotlightGlow(frame: spotlightFrame)
                        .allowsHitTesting(false)
                }

                informationCard
                    .frame(width: min(geometry.size.width - 40, 380))
                    .position(
                        x: geometry.size.width / 2,
                        y: cardCenterY(in: geometry)
                    )

                Button("Skip", action: onSkip)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                    .padding(.top, geometry.safeAreaInsets.top + 8)
                    .padding(.trailing, 18)
                    .accessibilityHint("Ends the tour and marks onboarding complete")
            }
            .contentShape(Rectangle())
        }
        .ignoresSafeArea()
        .animation(
            .spring(response: 0.48, dampingFraction: 0.86),
            value: currentStepIndex
        )
        .animation(
            .spring(response: 0.48, dampingFraction: 0.86),
            value: spotlightFrame
        )
        .accessibilityAddTraits(.isModal)
    }

    private var spotlightFrame: CGRect? {
        guard
            let highlightedElement = currentStep.highlightedElement,
            let frame = highlightFrames[highlightedElement],
            frame.width > 0,
            frame.height > 0
        else {
            return nil
        }

        return frame.insetBy(dx: -spotlightPadding, dy: -spotlightPadding)
    }

    private func dimmingLayer(in size: CGSize) -> some View {
        Canvas { context, _ in
            var path = Path(CGRect(origin: .zero, size: size))

            if let spotlightFrame {
                path.addRoundedRect(
                    in: spotlightFrame,
                    cornerSize: CGSize(
                        width: spotlightCornerRadius,
                        height: spotlightCornerRadius
                    )
                )
            }

            context.fill(
                path,
                with: .color(Color.black.opacity(0.65)),
                style: FillStyle(eoFill: true)
            )
        }
    }

    private func spotlightGlow(frame: CGRect) -> some View {
        RoundedRectangle(cornerRadius: spotlightCornerRadius, style: .continuous)
            .stroke(Color(red: 0.78, green: 0.68, blue: 1).opacity(0.9), lineWidth: 2)
            .frame(width: frame.width, height: frame.height)
            .shadow(color: Color.purple.opacity(0.8), radius: 14)
            .shadow(color: Color.white.opacity(0.35), radius: 4)
            .position(x: frame.midX, y: frame.midY)
    }

    private var informationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 9) {
                Text(currentStep.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(NestTheme.primaryText)

                Text(currentStep.description)
                    .font(.body)
                    .foregroundStyle(Color.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("\(currentStepIndex + 1) of \(steps.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(NestTheme.secondaryText)
                .accessibilityLabel("Step \(currentStepIndex + 1) of \(steps.count)")

            HStack(spacing: 12) {
                if currentStepIndex > 0 {
                    Button("Previous", action: showPreviousStep)
                        .buttonStyle(NestSecondaryButtonStyle())
                }

                Spacer(minLength: 0)

                Button(currentStep.primaryButtonTitle, action: performPrimaryAction)
                    .buttonStyle(NestPrimaryButtonStyle())
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.13, green: 0.10, blue: 0.23).opacity(0.97))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 24, y: 12)
        .id(currentStep.id)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    private func performPrimaryAction() {
        guard currentStepIndex < steps.count - 1 else {
            onFinish()
            return
        }

        withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
            currentStepIndex += 1
        }
    }

    private func showPreviousStep() {
        guard currentStepIndex > 0 else { return }

        withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
            currentStepIndex -= 1
        }
    }

    private func cardCenterY(in geometry: GeometryProxy) -> CGFloat {
        let minimumCenterY = geometry.safeAreaInsets.top + estimatedCardHeight / 2 + 24
        let maximumCenterY = geometry.size.height
            - geometry.safeAreaInsets.bottom
            - estimatedCardHeight / 2
            - 24

        guard let spotlightFrame else {
            return min(max(geometry.size.height / 2, minimumCenterY), maximumCenterY)
        }

        let gap: CGFloat = 22
        let aboveCenter = spotlightFrame.minY - gap - estimatedCardHeight / 2
        let belowCenter = spotlightFrame.maxY + gap + estimatedCardHeight / 2
        let preferredPosition = currentStep.preferredTooltipPosition ?? .below

        switch preferredPosition {
        case .above where aboveCenter >= minimumCenterY:
            return aboveCenter
        case .below where belowCenter <= maximumCenterY:
            return belowCenter
        case .above:
            return min(max(belowCenter, minimumCenterY), maximumCenterY)
        case .below:
            return min(max(aboveCenter, minimumCenterY), maximumCenterY)
        case .centered:
            return min(max(geometry.size.height / 2, minimumCenterY), maximumCenterY)
        }
    }
}
