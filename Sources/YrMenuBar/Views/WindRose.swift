import SwiftUI

/// yr.no app-style wind indicator: a ringed circle with the wind speed in the
/// centre, and a single straight arrow passing across the circle. The arrow
/// head points in the direction the wind is going (= from + 180°); the tail
/// sticks out the opposite side.
struct WindRose: View {
    let speedMs: Double?
    let fromDirectionDegrees: Double?
    let displaySpeed: String

    private let diameter: CGFloat = 44
    private let arrowLength: CGFloat = 64   // longer than the diameter, so it pokes out both sides
    private let headSize: CGFloat = 8

    var body: some View {
        ZStack {
            // Arrow first, so the circle outline draws over it where they intersect.
            arrow
                .rotationEffect(.degrees((fromDirectionDegrees ?? 0) + 180))
                .opacity(fromDirectionDegrees == nil ? 0.3 : 1)

            Circle()
                .strokeBorder(Color.white, lineWidth: 1.5)
                .frame(width: diameter, height: diameter)

            Text(displaySpeed)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(width: arrowLength, height: arrowLength)
    }

    /// Vertical arrow centred at (arrowLength/2, arrowLength/2) pointing UP.
    /// Rotation is applied by the parent.
    private var arrow: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let half = arrowLength / 2

            // Shaft
            var shaft = Path()
            shaft.move(to: CGPoint(x: cx, y: cy + half))     // bottom
            shaft.addLine(to: CGPoint(x: cx, y: cy - half))  // top (arrow tip)
            ctx.stroke(shaft, with: .color(.white), lineWidth: 2)

            // Arrowhead at the top
            var head = Path()
            head.move(to: CGPoint(x: cx, y: cy - half))               // tip
            head.addLine(to: CGPoint(x: cx - headSize, y: cy - half + headSize * 1.4))
            head.addLine(to: CGPoint(x: cx + headSize, y: cy - half + headSize * 1.4))
            head.closeSubpath()
            ctx.fill(head, with: .color(.white))
        }
    }
}
