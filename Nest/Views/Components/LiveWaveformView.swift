import SwiftUI

/// Scrolling live waveform driven by microphone amplitude and speech pace.
struct LiveWaveformView: View {
    let samples: [CGFloat]
    let density: CGFloat

    private var barWidth: CGFloat {
        max(1.5, 3.2 - density * 1.6)
    }

    private var barSpacing: CGFloat {
        max(0.8, 2.8 - density * 2.0)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: barSpacing) {
                if samples.isEmpty {
                    placeholderBars(in: geometry)
                } else {
                    ForEach(Array(samples.enumerated()), id: \.offset) { _, amplitude in
                        RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.55, green: 0.65, blue: 1.0),
                                        Color(red: 0.75, green: 0.50, blue: 0.98)
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(
                                width: barWidth,
                                height: barHeight(for: amplitude, in: geometry.size.height)
                            )
                            .animation(.easeOut(duration: 0.08), value: amplitude)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
        .animation(.easeInOut(duration: 0.12), value: density)
    }

    private func barHeight(for amplitude: CGFloat, in maxHeight: CGFloat) -> CGFloat {
        let minimumHeight = maxHeight * 0.08
        let variableHeight = amplitude * maxHeight * 0.92
        return max(minimumHeight, variableHeight)
    }

    private func placeholderBars(in geometry: GeometryProxy) -> some View {
        ForEach(0..<24, id: \.self) { index in
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .frame(width: 2.5, height: geometry.size.height * 0.1)
                .opacity(index % 3 == 0 ? 0.35 : 0.15)
        }
    }
}
