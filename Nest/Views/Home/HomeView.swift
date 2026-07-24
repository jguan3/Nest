import SwiftData
import SwiftUI

/// Home tab with a living nest bird, affirmations, and a gentle mood check-in.
struct HomeView: View {
    let activeOnboardingHighlight: OnboardingHighlight?

    @State private var affirmation = AffirmationStore.random()
    @State private var affirmationSwapID = UUID()
    @State private var showAffirmationSparkle = false
    @State private var nestPulse = false
    @AppStorage("nest.home.checkInCount") private var checkInCount = 0

    init(activeOnboardingHighlight: OnboardingHighlight? = nil) {
        self.activeOnboardingHighlight = activeOnboardingHighlight
    }

    var body: some View {
        ZStack {
            NestBackground()

            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Text("Home")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(NestTheme.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                        NestScene(isPulsing: nestPulse)
                            .frame(height: 300)
                            .padding(.horizontal, 12)

                        Text("Tap to fly · Hold to sleep · Drag anywhere")
                            .font(.caption)
                            .foregroundStyle(NestTheme.secondaryText)

                        ZStack {
                            Text(affirmation)
                                .font(.title3.weight(.medium))
                                .foregroundStyle(NestTheme.primaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 36)
                                .id(affirmationSwapID)
                                .transition(
                                    .asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                                        removal: .opacity.combined(with: .move(edge: .top))
                                    )
                                )

                            if showAffirmationSparkle {
                                AffirmationSparkleBurst()
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .frame(minHeight: 72)

                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                                affirmation = AffirmationStore.random(excluding: affirmation)
                                affirmationSwapID = UUID()
                                nestPulse.toggle()
                                showAffirmationSparkle = true
                            }
                            NestSoundPlayer.shared.play(.sparkle)
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(280))
                                withAnimation(.easeOut(duration: 0.15)) {
                                    showAffirmationSparkle = false
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.subheadline.weight(.semibold))
                                Text("Another affirmation")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(NestTheme.primaryText)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(NestTheme.cardBackground)
                                    .overlay(Capsule().strokeBorder(NestTheme.cardStroke, lineWidth: 1))
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Show another affirmation")

                        MoodCheckInCard {
                            checkInCount += 1
                        }
                        .onboardingAnchor(.moodCheckIn)
                        .id(OnboardingHighlight.moodCheckIn)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
                .onChange(of: activeOnboardingHighlight) { _, highlight in
                    guard highlight == .moodCheckIn else { return }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                        scrollProxy.scrollTo(OnboardingHighlight.moodCheckIn, anchor: .bottom)
                    }
                }
            }
        }
    }
}

/// Interactive scene with a cozy woven nest and a peach bird that walks, flies, and sleeps.
private struct NestScene: View {
    let isPulsing: Bool

    @State private var birdX: CGFloat = 0
    @State private var birdDragY: CGFloat = 0
    @State private var birdLift: CGFloat = 0
    @State private var facingRight = true
    @State private var isWalking = false
    @State private var walkBob = false
    @State private var isDragging = false
    @State private var isFlying = false
    @State private var wingFlap = false
    @State private var isSleeping = false
    @State private var dragOriginX: CGFloat = 0
    @State private var dragOriginY: CGFloat = 0
    @State private var pressStartedAt: Date?
    @State private var walkTask: Task<Void, Never>?
    @State private var flyTask: Task<Void, Never>?
    @State private var wingTask: Task<Void, Never>?
    @State private var nestBreath = false
    @State private var showFlightSparkles = false

    private let walkMinX: CGFloat = -110
    private let walkMaxX: CGFloat = 110
    private let dragMinY: CGFloat = -150
    private let dragMaxY: CGFloat = 40
    private let nestFloorY: CGFloat = 18

    var body: some View {
        ZStack {
            CozyNestIllustration(isPulsing: isPulsing, isBreathing: nestBreath)

            if showFlightSparkles {
                flightSparkles
                    .offset(x: birdX, y: birdY + 10)
                    .transition(.opacity)
            }

            walkingBird
                .offset(x: birdX, y: birdY)
                .gesture(birdInteractionGesture)
        }
        .offset(y: nestBreath ? -3.5 : 0)
        .animation(.easeInOut(duration: 0.4), value: isPulsing)
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: birdLift)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                nestBreath = true
            }
            restartWalking()
        }
        .onDisappear {
            walkTask?.cancel()
            walkTask = nil
            flyTask?.cancel()
            flyTask = nil
            wingTask?.cancel()
            wingTask = nil
        }
        .accessibilityLabel("Cute bird in a nest. Tap to fly, hold to sleep, drag to move.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Fly") { fly() }
    }

    private var birdY: CGFloat {
        nestFloorY
            + birdDragY
            + birdLift
            + (isPulsing && !isDragging && !isFlying ? -6 : 0)
            + (isSleeping ? 4 : 0)
    }

    private var walkingBird: some View {
        CuteNestBird(
            scale: 1.55,
            facingRight: facingRight,
            isWalking: (isWalking || isDragging) && !isFlying && !isSleeping,
            walkBob: walkBob,
            isFlying: isFlying || (isDragging && birdDragY < -20),
            wingFlap: wingFlap,
            isSleeping: isSleeping
        )
        .frame(width: 120, height: 120)
        .contentShape(Rectangle())
    }

    private var flightSparkles: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat([8, 11, 9, 7][index])))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .offset(
                        x: CGFloat([-18, 12, -8, 20][index]),
                        y: CGFloat([8, -6, 16, 0][index])
                    )
            }
        }
        .allowsHitTesting(false)
    }

    /// Single drag gesture that also detects taps and long-press sleep.
    private var birdInteractionGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let distance = hypot(value.translation.width, value.translation.height)
                if pressStartedAt == nil {
                    pressStartedAt = Date()
                }

                if !isDragging, distance > 12 {
                    beginDrag()
                }

                if isDragging {
                    let nextX = min(max(dragOriginX + value.translation.width, walkMinX), walkMaxX)
                    let nextY = min(max(dragOriginY + value.translation.height, dragMinY), dragMaxY)
                    facingRight = nextX >= birdX
                    birdX = nextX
                    birdDragY = nextY
                    walkBob.toggle()
                    if nextY < -24 {
                        isFlying = true
                        startWingFlapping()
                    }
                } else if !isSleeping,
                          distance < 12,
                          let pressStartedAt,
                          Date().timeIntervalSince(pressStartedAt) >= 0.45 {
                    setSleeping(true)
                }
            }
            .onEnded { value in
                let distance = hypot(value.translation.width, value.translation.height)
                let wasDragging = isDragging
                let wasSleeping = isSleeping
                isDragging = false
                pressStartedAt = nil

                if wasDragging {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                        if abs(birdDragY) < 18 {
                            birdDragY = 0
                        }
                        if birdDragY > -20 {
                            isFlying = false
                            wingFlap = false
                            wingTask?.cancel()
                            wingTask = nil
                        }
                    }
                    if !isSleeping, birdDragY > -20 {
                        restartWalking()
                    }
                } else if wasSleeping {
                    setSleeping(false)
                } else if distance < 12 {
                    fly()
                }
            }
    }

    private func beginDrag() {
        if isSleeping {
            setSleeping(false)
        }
        isDragging = true
        isWalking = true
        walkTask?.cancel()
        flyTask?.cancel()
        birdLift = 0
        showFlightSparkles = false
        dragOriginX = birdX
        dragOriginY = birdDragY
    }

    /// Lifts the bird into a short flight; repeated taps boost height.
    private func fly() {
        guard !isSleeping else {
            setSleeping(false)
            return
        }

        NestSoundPlayer.shared.play(.chirp)
        NestHaptics.softTap()
        isFlying = true
        isWalking = false
        walkTask?.cancel()
        showFlightSparkles = true

        let boost = min(birdLift - 42, -36)
        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
            birdLift = max(boost, -130)
        }

        startWingFlapping()

        flyTask?.cancel()
        flyTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    showFlightSparkles = false
                }
            }
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                    birdLift = 0
                    isFlying = false
                    wingFlap = false
                }
                wingTask?.cancel()
                wingTask = nil
                if !isSleeping {
                    restartWalking()
                }
            }
        }
    }

    private func startWingFlapping() {
        wingTask?.cancel()
        wingTask = Task {
            while !Task.isCancelled {
                await MainActor.run { wingFlap.toggle() }
                try? await Task.sleep(for: .milliseconds(110))
            }
        }
    }

    /// Puts the bird to sleep while the user holds, or wakes it.
    private func setSleeping(_ sleeping: Bool) {
        guard sleeping != isSleeping else { return }
        isSleeping = sleeping
        if sleeping {
            NestSoundPlayer.shared.play(.sleep)
            isFlying = false
            isWalking = false
            birdLift = 0
            showFlightSparkles = false
            walkTask?.cancel()
            flyTask?.cancel()
            wingTask?.cancel()
            wingFlap = false
        } else if !isDragging {
            restartWalking()
        }
    }

    /// Walks the bird left and right along the nest floor.
    private func restartWalking() {
        walkTask?.cancel()
        walkTask = Task {
            while !Task.isCancelled {
                guard !isDragging, !isFlying, !isSleeping else {
                    try? await Task.sleep(for: .milliseconds(200))
                    continue
                }

                await MainActor.run { isWalking = false }
                try? await Task.sleep(for: .seconds(Double.random(in: 0.6...1.4)))
                guard !Task.isCancelled, !isDragging, !isFlying, !isSleeping else { continue }

                let destination = CGFloat.random(in: walkMinX...walkMaxX)
                let distance = abs(destination - birdX)
                let duration = max(0.9, Double(distance) / 55)

                await MainActor.run {
                    facingRight = destination >= birdX
                    isWalking = true
                    birdDragY = 0
                }

                let steps = max(8, Int(duration * 10))
                let startX = birdX
                for step in 1...steps {
                    guard !Task.isCancelled, !isDragging, !isFlying, !isSleeping else { break }
                    let progress = CGFloat(step) / CGFloat(steps)
                    await MainActor.run {
                        birdX = startX + (destination - startX) * progress
                        walkBob.toggle()
                    }
                    try? await Task.sleep(for: .milliseconds(Int(duration * 1000 / Double(steps))))
                }

                await MainActor.run { isWalking = false }
            }
        }
    }
}

/// Soft woven nest bowl — a deep cup of crossed twigs with a soft hollow.
private struct CozyNestIllustration: View {
    let isPulsing: Bool
    let isBreathing: Bool

    private let bark = Color(red: 0.42, green: 0.28, blue: 0.16)
    private let twigDark = Color(red: 0.52, green: 0.34, blue: 0.20)
    private let twigMid = Color(red: 0.66, green: 0.46, blue: 0.28)
    private let twigLight = Color(red: 0.78, green: 0.58, blue: 0.38)
    private let straw = Color(red: 0.86, green: 0.7, blue: 0.48)
    private let moss = Color(red: 0.42, green: 0.55, blue: 0.32)

    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.85, green: 0.65, blue: 1.0).opacity(0.14),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 130
                    )
                )
                .frame(width: 240, height: 80)
                .offset(y: 68)

            Ellipse()
                .fill(Color.black.opacity(0.32))
                .frame(width: 210, height: 34)
                .blur(radius: 10)
                .offset(y: 96)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [twigDark, bark.opacity(0.95), bark],
                        center: UnitPoint(x: 0.5, y: 0.35),
                        startRadius: 10,
                        endRadius: 130
                    )
                )
                .frame(width: 250, height: 128)
                .offset(y: 58)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.22, green: 0.14, blue: 0.1),
                            bark.opacity(0.9),
                            twigMid.opacity(0.55)
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 85
                    )
                )
                .frame(width: 168, height: 78)
                .offset(y: 52)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            straw.opacity(0.55),
                            moss.opacity(0.4),
                            twigMid.opacity(0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 132, height: 42)
                .offset(y: 50)

            ForEach(0..<6, id: \.self) { ring in
                Ellipse()
                    .stroke(
                        [bark, twigDark, twigMid, twigLight, twigDark, straw.opacity(0.8)][ring],
                        style: StrokeStyle(
                            lineWidth: CGFloat([16, 13, 10, 8, 6, 4][ring]),
                            lineCap: .round,
                            dash: ring % 2 == 0 ? [] : [10, 5]
                        )
                    )
                    .frame(
                        width: 236 - CGFloat(ring) * 16,
                        height: 108 - CGFloat(ring) * 10
                    )
                    .offset(y: 54 + CGFloat(ring) * 1.5)
                    .opacity(0.9 - Double(ring) * 0.06)
            }

            ForEach(0..<34, id: \.self) { index in
                NestTwig(index: index)
            }

            Capsule()
                .fill(moss.opacity(0.55))
                .frame(width: 18, height: 5)
                .rotationEffect(.degrees(-20))
                .offset(x: -28, y: 46)
            Capsule()
                .fill(straw.opacity(0.65))
                .frame(width: 16, height: 4)
                .rotationEffect(.degrees(25))
                .offset(x: 24, y: 48)

            NestRimStick(length: 62, thickness: 5.5, rotation: -34, xOffset: -118, yOffset: 34, color: twigMid)
            NestRimStick(length: 54, thickness: 5, rotation: 30, xOffset: 116, yOffset: 32, color: twigLight)
            NestRimStick(length: 46, thickness: 4.2, rotation: -22, xOffset: -104, yOffset: 70, color: bark)
            NestRimStick(length: 50, thickness: 4, rotation: 24, xOffset: 106, yOffset: 72, color: twigMid)
            NestRimStick(length: 38, thickness: 3.4, rotation: 68, xOffset: -74, yOffset: 90, color: straw.opacity(0.9))
            NestRimStick(length: 36, thickness: 3.4, rotation: -64, xOffset: 78, yOffset: 92, color: bark.opacity(0.9))
            NestRimStick(length: 44, thickness: 3.8, rotation: -52, xOffset: -96, yOffset: 16, color: twigLight)
            NestRimStick(length: 42, thickness: 3.6, rotation: 48, xOffset: 94, yOffset: 14, color: twigMid)
            NestRimStick(length: 32, thickness: 3, rotation: 12, xOffset: -48, yOffset: 102, color: bark)
            NestRimStick(length: 30, thickness: 3, rotation: -16, xOffset: 52, yOffset: 104, color: twigMid)
            NestRimStick(length: 28, thickness: 2.6, rotation: 78, xOffset: -128, yOffset: 54, color: twigDark)
            NestRimStick(length: 26, thickness: 2.6, rotation: -74, xOffset: 126, yOffset: 56, color: twigLight)
        }
        .scaleEffect((isPulsing ? 1.03 : 1.0) * (isBreathing ? 1.016 : 1.0))
    }
}

/// One woven twig curved through the nest bowl.
private struct NestTwig: View {
    let index: Int

    private var twigColor: Color {
        let palette = [
            Color(red: 0.42, green: 0.28, blue: 0.16),
            Color(red: 0.55, green: 0.36, blue: 0.22),
            Color(red: 0.68, green: 0.48, blue: 0.3),
            Color(red: 0.78, green: 0.58, blue: 0.38),
            Color(red: 0.5, green: 0.34, blue: 0.2),
            Color(red: 0.72, green: 0.54, blue: 0.34)
        ]
        return palette[index % palette.count]
    }

    var body: some View {
        let width = 44 + CGFloat(index % 7) * 9
        let thickness = 2.4 + CGFloat(index % 4) * 0.9
        let opacity = 0.5 + Double(index % 5) * 0.1
        let rotation = Double(index) * 11.5 - 100
        let radius = 70.0 + Double(index % 6) * 9.0
        let angle = Double(index) * 0.42
        let xOffset = cos(angle) * radius
        let yOffset = 50 + sin(angle * 1.1) * 26 + CGFloat(index % 3) * 3.5

        Capsule()
            .fill(twigColor.opacity(opacity))
            .frame(width: width, height: thickness)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
    }
}

/// A short protruding stick on the nest rim.
/// - Parameters:
///   - length: Stick length in points.
///   - thickness: Stick thickness in points.
///   - rotation: Degrees to rotate the stick.
///   - xOffset: Horizontal placement relative to nest center.
///   - yOffset: Vertical placement relative to nest center.
///   - color: Fill color for the stick.
private struct NestRimStick: View {
    let length: CGFloat
    let thickness: CGFloat
    let rotation: Double
    let xOffset: CGFloat
    let yOffset: CGFloat
    let color: Color

    var body: some View {
        Capsule()
            .fill(color)
            .frame(width: length, height: thickness)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
    }
}

/// Brief sparkles that appear when the affirmation refreshes.
private struct AffirmationSparkleBurst: View {
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat([10, 14, 11, 13, 9][index])))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .offset(
                        x: CGFloat([-70, -30, 10, 45, 75][index]),
                        y: CGFloat([-18, 20, -28, 14, -8][index])
                    )
            }
        }
        .allowsHitTesting(false)
    }
}

/// Soft mood selector card for the Home screen; each tap appends a timed entry.
private struct MoodCheckInCard: View {
    let onCheckedIn: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodEntry.createdAt, order: .reverse) private var moodEntries: [MoodEntry]
    @State private var selectedMood: MoodOption?
    @State private var journalText = ""
    @State private var saveErrorMessage: String?
    @FocusState private var isJournalFocused: Bool

    private var todaysEntries: [MoodEntry] {
        MoodStore.todaysEntries(from: moodEntries)
    }

    private var latestToday: MoodOption? {
        MoodStore.latestToday(from: moodEntries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How are you landing right now?")
                .font(.headline)
                .foregroundStyle(NestTheme.primaryText)

            HStack(spacing: 10) {
                ForEach(MoodOption.allCases) { mood in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedMood = mood
                            saveErrorMessage = nil
                        }
                    } label: {
                        VStack(spacing: 6) {
                            MoodSymbolView(mood: mood, font: .body)
                            Text(mood.label)
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(
                            highlightedMood == mood ? Color.white : NestTheme.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    highlightedMood == mood
                                        ? Color.white.opacity(0.18)
                                        : Color.white.opacity(0.06)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Check in as \(mood.label)")
                }
            }

            if selectedMood != nil {
                journalSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let highlightedMood {
                Text(highlightedMood.response)
                    .font(.footnote)
                    .foregroundStyle(NestTheme.secondaryText)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if !todaysEntries.isEmpty {
                todaySoFarSection
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedMood)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(NestTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                )
        )
    }

    /// Mood shown as selected: local tap override, otherwise latest today.
    private var highlightedMood: MoodOption? {
        selectedMood ?? latestToday
    }

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's contributing to this feeling?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NestTheme.primaryText)

            TextField("Write a few thoughts... ", text: $journalText, axis: .vertical)
                .lineLimit(2...6)
                .focused($isJournalFocused)
                .foregroundStyle(NestTheme.primaryText)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                        )
                )
                .accessibilityLabel("Optional mood journal entry")

            HStack {
                if let saveErrorMessage {
                    Text(saveErrorMessage)
                        .font(.caption)
                        .foregroundStyle(Color.red.opacity(0.9))
                }

                Spacer()

                Button(action: saveCheckIn) {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(NestTheme.accentGradient))
                }
                .buttonStyle(.plain)
                .disabled(selectedMood == nil)
                .opacity(selectedMood == nil ? 0.4 : 1)
                .accessibilityLabel("Save mood check-in")
                .accessibilityHint("Saves the selected mood and optional journal entry")
            }
        }
    }

    /// Saves the current mood draft, leaving it available when persistence fails.
    private func saveCheckIn() {
        guard let selectedMood else { return }

        do {
            try MoodStore.insert(
                selectedMood,
                journalText: journalText,
                in: modelContext
            )
            isJournalFocused = false
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                self.selectedMood = nil
                journalText = ""
                saveErrorMessage = nil
            }
            onCheckedIn()
        } catch {
            saveErrorMessage = "We couldn't save this check-in. Please try again."
            print("MoodCheckInCard: failed to save mood entry — \(error.localizedDescription)")
        }
    }

    private var todaySoFarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today so far")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NestTheme.secondaryText)

            // Newest 3 by default; expand to see the rest of today’s check-ins.
            MoodEntryDayList(entries: todaysEntries, density: .compact)
        }
        .padding(.top, 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Today’s mood check-ins")
    }
}

#Preview {
    HomeView()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
