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

    /// Vertical arrow centred at (size/2, size/2) pointing UP, with the
    /// portion that would be inside the circle erased so only the head and
    /// tail stick out beyond the ring.
    private var arrow: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let half = arrowLength / 2
            let shaftWidth: CGFloat = 3.5

            // Shaft
            var shaft = Path()
            shaft.move(to: CGPoint(x: cx, y: cy + half))     // bottom
            shaft.addLine(to: CGPoint(x: cx, y: cy - half))  // top (arrow tip)
            ctx.stroke(shaft, with: .color(.white),
                       style: StrokeStyle(lineWidth: shaftWidth, lineCap: .round))

            // Arrowhead at the top
            var head = Path()
            head.move(to: CGPoint(x: cx, y: cy - half))               // tip
            head.addLine(to: CGPoint(x: cx - headSize, y: cy - half + headSize * 1.4))
            head.addLine(to: CGPoint(x: cx + headSize, y: cy - half + headSize * 1.4))
            head.closeSubpath()
            ctx.fill(head, with: .color(.white))

            // Erase the portion of the arrow that overlaps the circle (slightly
            // larger than the ring so the stroke isn't clipped).
            ctx.blendMode = .destinationOut
            let r = diameter / 2 + 1
            ctx.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r,
                                            width: r * 2, height: r * 2)),
                     with: .color(.black))
        }
    }
}
