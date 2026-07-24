import SwiftUI

/// A round peach bird that can walk, fly, or sleep while keeping a soft rounded style.
struct CuteNestBird: View {
    var scale: CGFloat = 1
    var facingRight = true
    var isWalking = false
    var walkBob = false
    var isFlying = false
    var wingFlap = false
    var isSleeping = false

    var body: some View {
        ZStack {
            if !isFlying {
                Ellipse()
                    .fill(Color.black.opacity(isSleeping ? 0.12 : 0.22))
                    .frame(width: 52, height: 11)
                    .offset(y: 38)
                    .scaleEffect(x: isWalking ? 0.85 : 1.0, y: 1)
            }

            // Feet tuck up while flying.
            if !isFlying {
                HStack(spacing: 13) {
                    Capsule()
                        .fill(Color(red: 0.92, green: 0.48, blue: 0.32))
                        .frame(width: 11, height: 5)
                        .offset(y: isWalking && walkBob ? -3 : 0)
                    Capsule()
                        .fill(Color(red: 0.92, green: 0.48, blue: 0.32))
                        .frame(width: 11, height: 5)
                        .offset(y: isWalking && !walkBob ? -3 : 0)
                }
                .offset(y: 36)
                .opacity(isSleeping ? 0.7 : 1)
            }

            // Soft peach body.
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.82, blue: 0.62),
                            Color(red: 0.96, green: 0.66, blue: 0.45),
                            Color(red: 0.9, green: 0.55, blue: 0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 60, height: 50)
                .offset(y: 10 + bodyBob)
                .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.45).opacity(0.25), radius: 6, y: 2)

            // Belly fluff.
            Ellipse()
                .fill(Color(red: 1.0, green: 0.94, blue: 0.84).opacity(0.95))
                .frame(width: 32, height: 26)
                .offset(y: 14 + bodyBob)

            // Wing.
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.62, blue: 0.42),
                            Color(red: 0.85, green: 0.48, blue: 0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 26, height: isFlying ? 16 : 13)
                .rotationEffect(.degrees(wingRotation))
                .offset(x: -21, y: 11 + bodyBob)

            // Head.
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.86, blue: 0.66),
                            Color(red: 0.97, green: 0.7, blue: 0.48)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .offset(x: 4, y: -17 + bodyBob)
                .shadow(color: Color.orange.opacity(0.15), radius: 4, y: 1)

            // Cheek.
            Circle()
                .fill(Color(red: 1.0, green: 0.55, blue: 0.55).opacity(isSleeping ? 0.35 : 0.6))
                .frame(width: 10, height: 8)
                .offset(x: 15, y: -11 + bodyBob)

            // Eye.
            Group {
                if isSleeping {
                    Capsule()
                        .fill(Color(red: 0.28, green: 0.18, blue: 0.2))
                        .frame(width: 8, height: 2)
                        .offset(x: 8, y: -18 + bodyBob)
                } else {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.14, blue: 0.16))
                        .frame(width: 7, height: 7)
                        .offset(x: 8, y: -19 + bodyBob)
                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: 2.8, height: 2.8)
                        .offset(x: 9.5, y: -20.5 + bodyBob)
                }
            }

            NestBirdBeak()
                .fill(Color(red: 0.96, green: 0.48, blue: 0.34))
                .frame(width: 13, height: 10)
                .offset(x: 24, y: -14 + bodyBob)

            if isSleeping {
                sleepZeeStack
            }
        }
        .frame(width: 110, height: 110)
        .scaleEffect(x: facingRight ? scale : -scale, y: scale)
        .offset(y: -10)
        .animation(.easeInOut(duration: 0.12), value: walkBob)
        .animation(.easeInOut(duration: 0.12), value: wingFlap)
    }

    private var bodyBob: CGFloat {
        if isFlying {
            return wingFlap ? -4 : 0
        }
        if isWalking && walkBob {
            return -3
        }
        if isSleeping {
            return 2
        }
        return 0
    }

    private var wingRotation: Double {
        if isFlying {
            return wingFlap ? -48 : -8
        }
        if isWalking {
            return -28
        }
        if isSleeping {
            return -8
        }
        return -16
    }

    private var sleepZeeStack: some View {
        VStack(spacing: 2) {
            Text("z")
                .font(.caption2.weight(.bold))
                .opacity(0.55)
            Text("Z")
                .font(.caption.weight(.bold))
                .opacity(0.75)
            Text("Z")
                .font(.footnote.weight(.bold))
                .opacity(0.9)
        }
        .foregroundStyle(Color.white.opacity(0.8))
        .offset(x: facingRight ? 34 : -34, y: -42)
        .scaleEffect(x: facingRight ? 1 : -1, y: 1)
    }
}

/// Tiny triangular beak for the nest bird.
struct NestBirdBeak: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - 2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + 3))
        path.closeSubpath()
        return path
    }
}
