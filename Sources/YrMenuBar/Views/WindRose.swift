import SwiftUI

/// yr.no app-style wind indicator: large arrow pointing in the direction the
/// wind is blowing TO, with the speed value underneath. No surrounding ring.
struct WindRose: View {
    let speedMs: Double?
    let fromDirectionDegrees: Double?
    let displaySpeed: String

    var body: some View {
        VStack(spacing: 0) {
            // SF Symbol points "north" (up) by default; rotate so it points
            // in the direction the wind is going (= from + 180°).
            Image(systemName: "location.north.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees((fromDirectionDegrees ?? 0) + 180))
                .opacity(fromDirectionDegrees == nil ? 0.3 : 1)
                .frame(height: 32)

            Text(displaySpeed)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(width: 64)
    }
}
