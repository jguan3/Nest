import SwiftData
import SwiftUI

/// Root tab shell for Nest — Home, Voice, Tools, and Personal.
struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var captureViewModel = CaptureViewModel()
    @State private var pendingTool: CopingTool?
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @AppStorage(NestAppTheme.storageKey) private var themeRaw = NestAppTheme.duskPurple.rawValue
    @State private var isOnboardingVisible = false
    @State private var onboardingOpacity = 0.0
    @State private var currentOnboardingStepIndex = 0
    @State private var onboardingFrames: [OnboardingHighlight: CGRect] = [:]

    private let onboardingSteps = OnboardingStep.tour

    private var activeOnboardingHighlight: OnboardingHighlight? {
        guard isOnboardingVisible else { return nil }
        return onboardingSteps[currentOnboardingStepIndex].highlightedElement
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                tabContent
                    .disabled(isOnboardingVisible)

                if isOnboardingVisible {
                    OnboardingOverlay(
                        steps: onboardingSteps,
                        currentStepIndex: $currentOnboardingStepIndex,
                        highlightFrames: onboardingFrames,
                        onSkip: completeOnboarding,
                        onFinish: completeOnboarding
                    )
                    .opacity(onboardingOpacity)
                    .zIndex(10)
                }
            }
            .coordinateSpace(name: "onboarding")
            .collectOnboardingFrames($onboardingFrames)
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: presentOnboardingIfNeeded)
        .onChange(of: onboardingCompleted) { _, completed in
            if !completed {
                presentOnboardingIfNeeded()
            }
        }
        .onChange(of: currentOnboardingStepIndex) { _, newIndex in
            guard let highlight = onboardingSteps[newIndex].highlightedElement else { return }
            selectedTab = highlight.tabIndex
        }
        .onChange(of: captureViewModel.pendingToolNavigation) { _, tool in
            guard let tool else { return }
            pendingTool = tool
            selectedTab = 2
            captureViewModel.pendingToolNavigation = nil
        }
    }

    private var tabContent: some View {
        TabView(selection: $selectedTab) {
            HomeView(activeOnboardingHighlight: activeOnboardingHighlight)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            CaptureView(viewModel: captureViewModel)
                .tabItem {
                    Label("Voice", systemImage: "waveform")
                }
                .tag(1)

            ToolsView(pendingTool: $pendingTool)
                .tabItem {
                    Label("Tools", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(2)

            PersonalView(activeOnboardingHighlight: activeOnboardingHighlight)
                .tabItem {
                    Label("Personal", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint((NestAppTheme(rawValue: themeRaw) ?? .duskPurple).tabTint)
    }

    /// Presents the tour once, with a launch argument for development resets.
    private func presentOnboardingIfNeeded() {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetOnboarding") {
            onboardingCompleted = false
        }
#endif

        guard !onboardingCompleted, !isOnboardingVisible else { return }
        currentOnboardingStepIndex = 0
        selectedTab = 0
        isOnboardingVisible = true
        withAnimation(.easeIn(duration: 0.3)) {
            onboardingOpacity = 1
        }
    }

    /// Persists completion immediately, then gently removes the blocking overlay.
    private func completeOnboarding() {
        onboardingCompleted = true
        withAnimation(.easeOut(duration: 0.32)) {
            onboardingOpacity = 0
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(320))
            isOnboardingVisible = false
            onboardingFrames = [:]
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Thought.self, ThoughtFolder.self], inMemory: true)
}
