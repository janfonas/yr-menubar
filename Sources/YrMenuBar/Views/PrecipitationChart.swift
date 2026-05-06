import SwiftUI

/// 90-minute precipitation mini-chart matching yr.no's app: filled blue
/// area showing precipitation intensity (mm/h) over 5-min steps.
struct PrecipitationChart: View {
    let series: [(time: Date, rate: Double)]
    /// Y-axis ceiling. Auto-derived from data with sane minimum.
    var maxRate: Double {
        let m = series.map(\.rate).max() ?? 0
        // Round up to a nice scale: 0.5, 1, 2, 4, 8 mm/h
        let ceilings: [Double] = [0.5, 1, 2, 4, 8, 16]
        return ceilings.first(where: { $0 >= max(m, 0.1) }) ?? 16
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .bottomLeading) {
                    // Y-axis grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<3) { i in
                            Divider()
                                .background(Color.white.opacity(0.25))
                            if i < 2 { Spacer() }
                        }
                    }

                    // Area chart (filled), drawn even when all zeros so the axis is visible.
                    if !series.isEmpty {
                        chartShape(in: geo.size)
                            .fill(LinearGradient(
                                colors: [Color.white.opacity(0.85),
                                         Color.white.opacity(0.35)],
                                startPoint: .top, endPoint: .bottom))
                        chartShape(in: geo.size, asLine: true)
                            .stroke(Color.white, lineWidth: 1.5)
                    }
                }
            }
            .frame(height: 50)

            // Time axis labels: now / +30 / +60 / +90
            HStack {
                Text("nå").font(.system(size: 9)).foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text("+30").font(.system(size: 9)).foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text("+60").font(.system(size: 9)).foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text("+90").font(.system(size: 9)).foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private func chartShape(in size: CGSize, asLine: Bool = false) -> Path {
        Path { p in
            let count = max(series.count - 1, 1)
            let dx = size.width / CGFloat(count)
            let scale = size.height / CGFloat(maxRate)

            for (i, point) in series.enumerated() {
                let x = CGFloat(i) * dx
                let y = size.height - CGFloat(point.rate) * scale
                if i == 0 {
                    if asLine {
                        p.move(to: CGPoint(x: x, y: y))
                    } else {
                        p.move(to: CGPoint(x: x, y: size.height))
                        p.addLine(to: CGPoint(x: x, y: y))
                    }
                } else {
                    p.addLine(to: CGPoint(x: x, y: y))
                }
            }

            if !asLine {
                let lastX = CGFloat(series.count - 1) * dx
                p.addLine(to: CGPoint(x: lastX, y: size.height))
                p.closeSubpath()
            }
        }
    }
}
