import SwiftData
import SwiftUI

/// Home tab with a living nest bird, affirmations, and a gentle mood check-in.
struct HomeView: View {
    @State private var affirmation = AffirmationStore.random()
    @State private var nestPulse = false
    @AppStorage("nest.home.checkInCount") private var checkInCount = 0

    var body: some View {
        ZStack {
            NestBackground()

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

                    Text("Your bird walks the nest — drag it if you want.")
                        .font(.caption)
                        .foregroundStyle(NestTheme.secondaryText)

                    Text(affirmation)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(NestTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .animation(.easeInOut(duration: 0.25), value: affirmation)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            affirmation = AffirmationStore.random(excluding: affirmation)
                            nestPulse.toggle()
                        }
                    } label: {
                        Text("Another one")
                            .font(.subheadline.weight(.semibold))
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

/// Interactive scene with a cozy woven nest and a peach bird that walks along it.
private struct NestScene: View {
    let isPulsing: Bool

    @State private var birdX: CGFloat = 0
    @State private var facingRight = true
    @State private var isWalking = false
    @State private var walkBob = false
    @State private var isDragging = false
    @State private var dragOriginX: CGFloat = 0
    @State private var walkTask: Task<Void, Never>?
    @State private var nestBreath = false

    private let walkMinX: CGFloat = -78
    private let walkMaxX: CGFloat = 78
    private let nestFloorY: CGFloat = 18

    var body: some View {
        ZStack {
            CozyNestIllustration(isPulsing: isPulsing, isBreathing: nestBreath)

            walkingBird
                .offset(x: birdX, y: birdY)
                .gesture(birdDrag)

            NestLeafAccent()
        }
        // Subtle float on the whole scene so the peach bird stays seated in the nest.
        .offset(y: nestBreath ? -3.5 : 0)
        .animation(.easeInOut(duration: 0.4), value: isPulsing)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                nestBreath = true
            }
            restartWalking()
        }
        .onDisappear {
            walkTask?.cancel()
            walkTask = nil
        }
        .accessibilityLabel("Cute bird walking in a nest. Drag to move.")
    }

    private var birdY: CGFloat {
        nestFloorY + (isPulsing && !isDragging ? -6 : 0)
    }

    private var walkingBird: some View {
        CuteNestBird(
            scale: 1.6,
            facingRight: facingRight,
            isWalking: isWalking || isDragging,
            walkBob: walkBob
        )
    }

    private var birdDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    isWalking = true
                    dragOriginX = birdX
                }
                let nextX = min(max(dragOriginX + value.translation.width, walkMinX), walkMaxX)
                facingRight = nextX >= birdX
                birdX = nextX
                walkBob.toggle()
            }
            .onEnded { _ in
                isDragging = false
                restartWalking()
            }
    }

    /// Walks the bird left and right along the nest floor.
    private func restartWalking() {
        walkTask?.cancel()
        walkTask = Task {
            while !Task.isCancelled {
                guard !isDragging else {
                    try? await Task.sleep(for: .milliseconds(200))
                    continue
                }

                await MainActor.run { isWalking = false }
                try? await Task.sleep(for: .seconds(Double.random(in: 0.6...1.4)))
                guard !Task.isCancelled, !isDragging else { continue }

                let destination = CGFloat.random(in: walkMinX...walkMaxX)
                let distance = abs(destination - birdX)
                let duration = max(0.9, Double(distance) / 55)

                await MainActor.run {
                    facingRight = destination >= birdX
                    isWalking = true
                }

                let steps = max(8, Int(duration * 10))
                let startX = birdX
                for step in 1...steps {
                    guard !Task.isCancelled, !isDragging else { break }
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

/// Soft, woven nest bowl with warm browns and gentle shading.
private struct CozyNestIllustration: View {
    let isPulsing: Bool
    let isBreathing: Bool

    private let outerTwig = Color(red: 0.52, green: 0.36, blue: 0.24)
    private let midTwig = Color(red: 0.66, green: 0.47, blue: 0.31)
    private let lightTwig = Color(red: 0.78, green: 0.60, blue: 0.42)
    private let softTwig = Color(red: 0.86, green: 0.70, blue: 0.52)
    private let hollow = Color(red: 0.34, green: 0.24, blue: 0.16)

    var body: some View {
        ZStack {
            // Soft ambient glow that ties into the app palette.
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.85, green: 0.65, blue: 1.0).opacity(0.20),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 120
                    )
                )
                .frame(width: 220, height: 70)
                .offset(y: 58)

            // Nest shadow / seated hollow.
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            hollow.opacity(0.50),
                            hollow.opacity(0.22),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 6,
                        endRadius: 100
                    )
                )
                .frame(width: 206, height: 70)
                .offset(y: 58)

            // Soft inner bedding.
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            softTwig.opacity(0.55),
                            midTwig.opacity(0.40),
                            hollow.opacity(0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 176, height: 58)
                .offset(y: 56)

            // Outer bowl rim.
            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [outerTwig, midTwig, outerTwig.opacity(0.88)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                .frame(width: 268, height: 116)
                .offset(y: 54)

            // Mid woven rim.
            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [lightTwig.opacity(0.85), midTwig, lightTwig.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 238, height: 96)
                .offset(y: 56)

            // Soft highlight ring.
            Ellipse()
                .stroke(softTwig.opacity(0.45), lineWidth: 5)
                .frame(width: 208, height: 80)
                .offset(y: 57)

            // Inner scoop edge.
            Ellipse()
                .stroke(outerTwig.opacity(0.55), lineWidth: 5)
                .frame(width: 186, height: 68)
                .offset(y: 58)

            ForEach(0..<18, id: \.self) { index in
                NestTwig(index: index)
            }

            NestRimStick(length: 52, thickness: 4.5, rotation: -26, xOffset: -116, yOffset: 44, color: midTwig)
            NestRimStick(length: 46, thickness: 4, rotation: 30, xOffset: 114, yOffset: 42, color: lightTwig)
            NestRimStick(length: 40, thickness: 3.5, rotation: -10, xOffset: -94, yOffset: 78, color: outerTwig)
            NestRimStick(length: 44, thickness: 3.5, rotation: 14, xOffset: 96, yOffset: 80, color: midTwig)
            NestRimStick(length: 34, thickness: 3, rotation: 58, xOffset: -68, yOffset: 92, color: softTwig.opacity(0.9))
            NestRimStick(length: 32, thickness: 3, rotation: -54, xOffset: 70, yOffset: 94, color: outerTwig.opacity(0.9))
        }
        .scaleEffect((isPulsing ? 1.03 : 1.0) * (isBreathing ? 1.016 : 1.0))
    }
}

/// One woven twig curved through the nest bowl.
private struct NestTwig: View {
    let index: Int

    private var twigColor: Color {
        let palette = [
            Color(red: 0.52, green: 0.36, blue: 0.22),
            Color(red: 0.66, green: 0.46, blue: 0.28),
            Color(red: 0.74, green: 0.56, blue: 0.36),
            Color(red: 0.48, green: 0.32, blue: 0.18),
            Color(red: 0.80, green: 0.64, blue: 0.46)
        ]
        return palette[index % palette.count]
    }

    var body: some View {
        let width = 32 + CGFloat(index % 5) * 9
        let thickness = 2.4 + CGFloat(index % 3) * 0.7
        let opacity = 0.50 + Double(index % 4) * 0.1
        let rotation = Double(index) * 17 - 80
        let xOffset = cos(Double(index) * 0.55) * 92
        let yOffset = 50 + sin(Double(index) * 0.7) * 20 + CGFloat(index % 3) * 2.5

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

/// Decorative leaf beside the nest.
private struct NestLeafAccent: View {
    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 42))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.55, green: 0.85, blue: 0.65),
                        Color(red: 0.35, green: 0.7, blue: 0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .offset(x: 108, y: -2)
            .opacity(0.9)
    }
}

/// A round peach bird that can face either way and bob while walking.
private struct CuteNestBird: View {
    var scale: CGFloat = 1
    var facingRight = true
    var isWalking = false
    var walkBob = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.2))
                .frame(width: 54, height: 12)
                .offset(y: 36)
                .scaleEffect(x: isWalking ? 0.85 : 1.0, y: 1)

            // Feet
            HStack(spacing: 14) {
                Capsule()
                    .fill(Color(red: 0.9, green: 0.45, blue: 0.3))
                    .frame(width: 10, height: 5)
                    .offset(y: isWalking && walkBob ? -3 : 0)
                Capsule()
                    .fill(Color(red: 0.9, green: 0.45, blue: 0.3))
                    .frame(width: 10, height: 5)
                    .offset(y: isWalking && !walkBob ? -3 : 0)
            }
            .offset(y: 34)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.78, blue: 0.55),
                            Color(red: 0.92, green: 0.62, blue: 0.42)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 58, height: 48)
                .offset(y: 10 + (isWalking && walkBob ? -3 : 0))

            Ellipse()
                .fill(Color(red: 1.0, green: 0.92, blue: 0.78))
                .frame(width: 30, height: 24)
                .offset(y: 14 + (isWalking && walkBob ? -3 : 0))

            Capsule()
                .fill(Color(red: 0.88, green: 0.55, blue: 0.38))
                .frame(width: 24, height: 13)
                .rotationEffect(.degrees(isWalking ? -28 : -18))
                .offset(x: -20, y: 12 + (isWalking && walkBob ? -2 : 0))

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.82, blue: 0.58),
                            Color(red: 0.95, green: 0.68, blue: 0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 38, height: 38)
                .offset(x: 5, y: -16 + (isWalking && walkBob ? -3 : 0))

            Circle()
                .fill(Color(red: 1.0, green: 0.55, blue: 0.55).opacity(0.55))
                .frame(width: 9, height: 7)
                .offset(x: 16, y: -11)

            Circle()
                .fill(Color(red: 0.22, green: 0.16, blue: 0.18))
                .frame(width: 6, height: 6)
                .offset(x: 9, y: -18)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 2.5, height: 2.5)
                .offset(x: 10, y: -19)

            NestBirdBeak()
                .fill(Color(red: 0.95, green: 0.45, blue: 0.32))
                .frame(width: 12, height: 9)
                .offset(x: 23, y: -13)
        }
        .frame(width: 100, height: 100)
        .scaleEffect(x: facingRight ? scale : -scale, y: scale)
        .offset(y: -10)
        .animation(.easeInOut(duration: 0.12), value: walkBob)
    }
}

/// Tiny triangular beak for the nest bird.
private struct NestBirdBeak: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - 2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + 3))
        path.closeSubpath()
        return path
    }
}

/// Soft mood selector card for the Home screen; each tap appends a timed entry.
private struct MoodCheckInCard: View {
    let onCheckedIn: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MoodEntry.createdAt, order: .reverse) private var moodEntries: [MoodEntry]
    @State private var selectedMood: MoodOption?

    private var todaysEntries: [MoodEntry] {
        MoodStore.todaysEntries(from: moodEntries)
    }

    private var latestToday: MoodOption? {
        MoodStore.latestToday(from: moodEntries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How are you landing today?")
                .font(.headline)
                .foregroundStyle(NestTheme.primaryText)

            HStack(spacing: 10) {
                ForEach(MoodOption.allCases) { mood in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedMood = mood
                        }
                        MoodStore.insert(mood, in: modelContext)
                        onCheckedIn()
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
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(NestTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                )
        )
        .onAppear {
            if selectedMood == nil {
                selectedMood = latestToday
            }
        }
        .onChange(of: latestToday) { _, newValue in
            if selectedMood == nil {
                selectedMood = newValue
            }
        }
    }

    /// Mood shown as selected: local tap override, otherwise latest today.
    private var highlightedMood: MoodOption? {
        selectedMood ?? latestToday
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
