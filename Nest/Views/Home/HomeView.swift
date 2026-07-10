import SwiftUI

/// Home tab with a living nest bird, affirmations, and a gentle mood check-in.
struct HomeView: View {
    @State private var affirmation = AffirmationStore.random()
    @State private var nestPulse = false
    @State private var selectedMood: MoodOption? = MoodStore.todayMood()
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

                    MoodCheckInCard(selectedMood: $selectedMood) {
                        checkInCount += 1
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

/// Interactive nest scene with a bird that walks along the nest.
private struct NestScene: View {
    let isPulsing: Bool

    @State private var birdX: CGFloat = 0
    @State private var facingRight = true
    @State private var isWalking = false
    @State private var walkBob = false
    @State private var isDragging = false
    @State private var dragOriginX: CGFloat = 0
    @State private var walkTask: Task<Void, Never>?

    private let walkMinX: CGFloat = -78
    private let walkMaxX: CGFloat = 78
    private let nestFloorY: CGFloat = 18

    var body: some View {
        ZStack {
            NestBowl(isPulsing: isPulsing)

            walkingBird
                .offset(x: birdX, y: birdY)
                .gesture(birdDrag)

            NestLeafAccent()
        }
        .animation(.easeInOut(duration: 0.4), value: isPulsing)
        .onAppear { restartWalking() }
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

/// Nest bowl and twigs behind the bird.
private struct NestBowl: View {
    let isPulsing: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.85, green: 0.65, blue: 1.0).opacity(0.22),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 120
                    )
                )
                .frame(width: 220, height: 70)
                .offset(y: 58)

            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.72, green: 0.55, blue: 1.0).opacity(0.65),
                            Color(red: 0.45, green: 0.55, blue: 1.0).opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 280, height: 128)
                .offset(y: 52)
                .scaleEffect(isPulsing ? 1.03 : 1.0)

            Ellipse()
                .stroke(Color.white.opacity(0.22), lineWidth: 5)
                .frame(width: 218, height: 87)
                .offset(y: 60)

            ForEach(0..<8, id: \.self) { index in
                NestTwig(index: index)
            }
        }
    }
}

/// One twig mark inside the nest bowl.
private struct NestTwig: View {
    let index: Int

    var body: some View {
        let width = 24 + CGFloat(index % 4) * 8
        let opacity = 0.12 + Double(index % 3) * 0.04
        let rotation = Double(index) * 12 - 42
        let xOffset = CGFloat(index) * 26 - 91
        let yOffset = 40 + CGFloat(abs(index - 3)) * 5

        Capsule()
            .fill(Color.white.opacity(opacity))
            .frame(width: width, height: 5)
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

/// Mood choices for a low-friction daily check-in.
enum MoodOption: String, CaseIterable, Identifiable {
    case calm
    case okay
    case tired
    case anxious
    case heavy

    var id: String { rawValue }

    var label: String {
        switch self {
        case .calm: "Calm"
        case .okay: "Okay"
        case .tired: "Tired"
        case .anxious: "Anxious"
        case .heavy: "Heavy"
        }
    }

    var symbol: String {
        switch self {
        case .calm: "sun.max.fill"
        case .okay: "cloud.sun.fill"
        case .tired: "moon.fill"
        case .anxious: "cloud.bolt.fill"
        case .heavy: "cloud.rain.fill"
        }
    }

    var response: String {
        switch self {
        case .calm: "Nice. Let that softness stay a little longer."
        case .okay: "Okay is a valid place to be."
        case .tired: "Rest counts. You don’t have to earn it."
        case .anxious: "You’re safe enough to take one slower breath."
        case .heavy: "Heavy feelings still belong here."
        }
    }
}

/// Persists today’s mood with UserDefaults.
enum MoodStore {
    private static let moodKey = "nest.mood.today.value"
    private static let dateKey = "nest.mood.today.date"

    /// Returns today’s saved mood, if any.
    static func todayMood() -> MoodOption? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        guard UserDefaults.standard.string(forKey: dateKey) == today,
              let raw = UserDefaults.standard.string(forKey: moodKey),
              let mood = MoodOption(rawValue: raw) else {
            return nil
        }
        return mood
    }

    /// Saves a mood for today.
    static func save(_ mood: MoodOption) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        UserDefaults.standard.set(formatter.string(from: Date()), forKey: dateKey)
        UserDefaults.standard.set(mood.rawValue, forKey: moodKey)
    }
}

/// Soft mood selector card for the Home screen.
private struct MoodCheckInCard: View {
    @Binding var selectedMood: MoodOption?
    let onCheckedIn: () -> Void

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
                        MoodStore.save(mood)
                        onCheckedIn()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mood.symbol)
                                .font(.body)
                            Text(mood.label)
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(
                            selectedMood == mood ? Color.white : NestTheme.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    selectedMood == mood
                                        ? Color.white.opacity(0.18)
                                        : Color.white.opacity(0.06)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if let selectedMood {
                Text(selectedMood.response)
                    .font(.footnote)
                    .foregroundStyle(NestTheme.secondaryText)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
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
    }
}

#Preview {
    HomeView()
}
