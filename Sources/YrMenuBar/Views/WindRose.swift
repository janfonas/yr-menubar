import SwiftUI

/// Compact wind rose: ringed circle with a rotated arrow on the perimeter
/// pointing inward (toward the source direction), and the wind speed in the centre.
struct WindRose: View {
    let speedMs: Double?
    let fromDirectionDegrees: Double?
    let displaySpeed: String

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)

            if let dir = fromDirectionDegrees {
                // Arrow at perimeter at the source direction, pointing inward
                arrow
                    .frame(width: 10, height: 12)
                    .foregroundStyle(.white)
                    .offset(y: -22)            // sit on the top of the ring
                    .rotationEffect(.degrees(dir)) // rotate around centre
            }

            VStack(spacing: 0) {
                Text(displaySpeed)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
        }
        .frame(width: 50, height: 50)
    }

    private var arrow: some View {
        // Solid down-pointing triangle (tip at bottom, toward centre)
        Path { p in
            p.move(to: CGPoint(x: 5, y: 12))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 10, y: 0))
            p.closeSubpath()
        }
        .fill(Color.white)
    }
}
