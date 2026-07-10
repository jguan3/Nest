import SwiftUI

/// Continuous dynamic sine wave with layered gradient glow.
struct RecordingWaveformView: View {
    let amplitude: CGFloat
    let density: CGFloat
    let samples: [CGFloat]

    private var waveFrequency: CGFloat {
        1.1 + density * 3.0
    }

    private var waveAmplitude: CGFloat {
        0.14 + amplitude * 0.42
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let elapsed = CGFloat(timeline.date.timeIntervalSinceReferenceDate)
                let phase = elapsed * (1.6 + density * 2.4)

                drawWave(
                    in: &context,
                    size: size,
                    phase: phase,
                    amplitudeScale: 1.0,
                    strokeWidth: 3.5,
                    opacity: 1.0,
                    blur: false
                )

                drawWave(
                    in: &context,
                    size: size,
                    phase: phase + 0.6,
                    amplitudeScale: 0.55,
                    strokeWidth: 6.0,
                    opacity: 0.35,
                    blur: true
                )

                drawWave(
                    in: &context,
                    size: size,
                    phase: phase - 0.35,
                    amplitudeScale: 0.35,
                    strokeWidth: 10.0,
                    opacity: 0.2,
                    blur: true
                )
            }
        }
        .background(Color.clear)
    }

    private func drawWave(
        in context: inout GraphicsContext,
        size: CGSize,
        phase: CGFloat,
        amplitudeScale: CGFloat,
        strokeWidth: CGFloat,
        opacity: Double,
        blur: Bool
    ) {
        let path = wavePath(size: size, phase: phase, amplitudeScale: amplitudeScale)
        var strokeContext = context

        if blur {
            strokeContext.addFilter(.blur(radius: 6))
        }

        strokeContext.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.55, green: 0.40, blue: 1.0).opacity(opacity),
                    Color(red: 0.75, green: 0.45, blue: 0.98).opacity(opacity),
                    Color(red: 1.0, green: 0.45, blue: 0.70).opacity(opacity),
                    Color(red: 0.50, green: 0.60, blue: 1.0).opacity(opacity)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: 0)
            ),
            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
        )
    }

    private func wavePath(size: CGSize, phase: CGFloat, amplitudeScale: CGFloat) -> Path {
        let midY = size.height / 2
        let width = size.width
        let step = max(1.2, 3.2 - density * 2.0)
        var path = Path()
        var started = false
        var x: CGFloat = 0

        while x <= width {
            let progress = x / max(width, 1)
            let sampleIndex = min(
                samples.count - 1,
                Int(progress * CGFloat(max(samples.count - 1, 1)))
            )
            let sampleBoost = samples.indices.contains(sampleIndex) ? samples[sampleIndex] : amplitude
            let localAmplitude = waveAmplitude * amplitudeScale * (0.5 + sampleBoost * 0.8)
            let y = midY + sin((progress * .pi * 2 * waveFrequency * 3) + phase) * localAmplitude * size.height

            if started {
                path.addLine(to: CGPoint(x: x, y: y))
            } else {
                path.move(to: CGPoint(x: x, y: y))
                started = true
            }
            x += step
        }

        return path
    }
}
