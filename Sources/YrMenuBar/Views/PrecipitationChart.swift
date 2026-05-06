import SwiftUI

/// 90-minute precipitation mini-chart matching yr.no's app: filled blue
/// area showing precipitation intensity (mm/h) over 5-min steps.
/// When the entire series is below `minDisplayRate` the chart collapses
/// to a single dry baseline rather than two stranded grid lines.
struct PrecipitationChart: View {
    let series: [(time: Date, rate: Double)]

    /// Below this rate (mm/h) the series is considered "dry" and the chart
    /// hides the gridlines, drawing only a faint baseline.
    private let minDisplayRate: Double = 0.05

    private var hasRain: Bool {
        series.contains(where: { $0.rate >= minDisplayRate })
    }

    /// Y-axis ceiling. Auto-derived from data with sane scale steps.
    private var maxRate: Double {
        let m = series.map(\.rate).max() ?? 0
        let ceilings: [Double] = [0.5, 1, 2, 4, 8, 16]
        return ceilings.first(where: { $0 >= max(m, minDisplayRate) }) ?? 16
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .bottomLeading) {
                    if hasRain {
                        // Two faint horizontal grid lines (1/3 and 2/3) only when there's rain.
                        VStack(spacing: 0) {
                            ForEach(0..<2) { _ in
                                Spacer()
                                Rectangle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(height: 0.5)
                            }
                            Spacer()
                        }

                        chartShape(in: geo.size)
                            .fill(LinearGradient(
                                colors: [Color.white.opacity(0.85),
                                         Color.white.opacity(0.35)],
                                startPoint: .top, endPoint: .bottom))
                        chartShape(in: geo.size, asLine: true)
                            .stroke(Color.white, lineWidth: 1.5)
                    } else {
                        // Single dry baseline at the bottom.
                        Rectangle()
                            .fill(Color.white.opacity(0.35))
                            .frame(height: 1)
                    }
                }
            }
            .frame(height: hasRain ? 50 : 12)

            // Time axis labels.
            HStack {
                Text(L10n.t(.now).lowercased()).font(.system(size: 9)).foregroundStyle(.white.opacity(0.85))
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
