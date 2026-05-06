import SwiftUI

/// Renders custom weather illustrations using SwiftUI Canvas based on a met.no symbol_code.
struct WeatherCanvas: View {
    let symbolCode: String?
    var animated: Bool = false
    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: animated ? 0.05 : 60)) { context in
            Canvas { ctx, size in
                draw(ctx: &ctx, size: size, time: context.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private func draw(ctx: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let s = min(size.width, size.height)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let code = symbolCode ?? "cloudy"
        let isNight = code.contains("_night")
        let isPolar = code.contains("_polartwilight")
        let base = code
            .replacingOccurrences(of: "_day", with: "")
            .replacingOccurrences(of: "_night", with: "")
            .replacingOccurrences(of: "_polartwilight", with: "")

        let hasSun = ["clearsky","fair","partlycloudy"].contains(base)
            || base.contains("rainshowers") || base.contains("snowshowers") || base.contains("sleetshowers")
        let hasCloud = base != "clearsky"
        let isHeavyCloud = ["cloudy","rain","heavyrain","snow","heavysnow","sleet","heavysleet","fog"].contains(base)
            || base.contains("andthunder")
        let hasRain = base.contains("rain") || base.contains("sleet")
        let hasSnow = base.contains("snow") || base.contains("sleet")
        let hasThunder = base.contains("thunder")
        let hasFog = base == "fog"
        let isLight = base.hasPrefix("light")
        let isHeavy = base.hasPrefix("heavy")

        // Sun or Moon
        if hasSun {
            let sunCenter = hasCloud ? CGPoint(x: center.x - s * 0.18, y: center.y - s * 0.18) : center
            let sunRadius = s * (hasCloud ? 0.18 : 0.28)
            if isNight || isPolar {
                drawMoon(ctx: &ctx, center: sunCenter, radius: sunRadius)
            } else {
                drawSun(ctx: &ctx, center: sunCenter, radius: sunRadius, time: time)
            }
        }

        if hasFog {
            drawFog(ctx: &ctx, size: size)
        }

        if hasCloud {
            drawCloud(ctx: &ctx, center: CGPoint(x: center.x + (hasSun ? s*0.05 : 0), y: center.y - s*0.02),
                      scale: s * (isHeavyCloud ? 0.55 : 0.45),
                      dark: isHeavyCloud)
        }

        if hasRain {
            drawRain(ctx: &ctx, center: CGPoint(x: center.x, y: center.y + s*0.18),
                     width: s * 0.45,
                     density: isHeavy ? 9 : (isLight ? 4 : 6),
                     time: time, animated: animated)
        }
        if hasSnow {
            drawSnow(ctx: &ctx, center: CGPoint(x: center.x, y: center.y + s*0.18),
                     width: s * 0.45,
                     count: isHeavy ? 7 : (isLight ? 3 : 5),
                     time: time, animated: animated)
        }
        if hasThunder {
            drawBolt(ctx: &ctx, center: CGPoint(x: center.x + s*0.05, y: center.y + s*0.1), size: s * 0.25)
        }
    }

    // MARK: drawing helpers
    private func drawSun(ctx: inout GraphicsContext, center: CGPoint, radius: CGFloat, time: TimeInterval) {
        let rays = Path { p in
            for i in 0..<8 {
                let a = (Double(i) / 8) * .pi * 2
                let inner = CGPoint(x: center.x + cos(a) * radius * 1.15, y: center.y + sin(a) * radius * 1.15)
                let outer = CGPoint(x: center.x + cos(a) * radius * 1.55, y: center.y + sin(a) * radius * 1.55)
                p.move(to: inner)
                p.addLine(to: outer)
            }
        }
        ctx.stroke(rays, with: .color(.orange), lineWidth: max(2, radius * 0.12))
        let body = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius*2, height: radius*2))
        ctx.fill(body, with: .linearGradient(
            Gradient(colors: [.yellow, .orange]),
            startPoint: CGPoint(x: center.x - radius, y: center.y - radius),
            endPoint: CGPoint(x: center.x + radius, y: center.y + radius)))
    }

    private func drawMoon(ctx: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let full = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius*2, height: radius*2))
        ctx.fill(full, with: .color(Color(white: 0.95)))
        let cutout = Path(ellipseIn: CGRect(x: center.x - radius*0.5, y: center.y - radius*1.1, width: radius*2, height: radius*2))
        ctx.blendMode = .destinationOut
        ctx.fill(cutout, with: .color(.black))
        ctx.blendMode = .normal
    }

    private func drawCloud(ctx: inout GraphicsContext, center: CGPoint, scale: CGFloat, dark: Bool) {
        let cloud = Path { p in
            let r1: CGFloat = scale * 0.35
            let r2: CGFloat = scale * 0.45
            let r3: CGFloat = scale * 0.32
            p.addEllipse(in: CGRect(x: center.x - scale*0.6, y: center.y - r1, width: r1*2, height: r1*2))
            p.addEllipse(in: CGRect(x: center.x - r2, y: center.y - r2*1.1, width: r2*2, height: r2*2))
            p.addEllipse(in: CGRect(x: center.x + scale*0.15, y: center.y - r3, width: r3*2, height: r3*2))
            p.addRoundedRect(in: CGRect(x: center.x - scale*0.7, y: center.y - scale*0.05,
                                        width: scale*1.45, height: scale*0.4),
                             cornerSize: CGSize(width: scale*0.2, height: scale*0.2))
        }
        let top = dark ? Color(white: 0.55) : Color(white: 0.95)
        let bot = dark ? Color(white: 0.35) : Color(white: 0.75)
        ctx.fill(cloud, with: .linearGradient(
            Gradient(colors: [top, bot]),
            startPoint: CGPoint(x: center.x, y: center.y - scale),
            endPoint: CGPoint(x: center.x, y: center.y + scale*0.4)))
    }

    private func drawRain(ctx: inout GraphicsContext, center: CGPoint, width: CGFloat, density: Int, time: TimeInterval, animated: Bool) {
        let dropLen = width * 0.12
        for i in 0..<density {
            let t = Double(i) / Double(density)
            let x = center.x - width/2 + width * CGFloat(t) + width * 0.05
            let phase = animated ? CGFloat(((time * 1.5) + Double(i) * 0.3).truncatingRemainder(dividingBy: 1.0)) : 0.4
            let y = center.y - dropLen + dropLen * 2 * phase
            var p = Path()
            p.move(to: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x - dropLen*0.25, y: y + dropLen))
            ctx.stroke(p, with: .color(.blue), lineWidth: max(1.5, width*0.025))
        }
    }

    private func drawSnow(ctx: inout GraphicsContext, center: CGPoint, width: CGFloat, count: Int, time: TimeInterval, animated: Bool) {
        for i in 0..<count {
            let t = Double(i) / Double(count)
            let x = center.x - width/2 + width * CGFloat(t) + width*0.05
            let phase = animated ? CGFloat(((time * 0.6) + Double(i) * 0.4).truncatingRemainder(dividingBy: 1.0)) : 0.4
            let y = center.y - width*0.1 + width*0.25 * phase
            let r = width * 0.04
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r*2, height: r*2)),
                     with: .color(.white))
            // small cross
            var cross = Path()
            cross.move(to: CGPoint(x: x - r*1.5, y: y))
            cross.addLine(to: CGPoint(x: x + r*1.5, y: y))
            cross.move(to: CGPoint(x: x, y: y - r*1.5))
            cross.addLine(to: CGPoint(x: x, y: y + r*1.5))
            ctx.stroke(cross, with: .color(Color(white: 0.85)), lineWidth: 1)
        }
    }

    private func drawBolt(ctx: inout GraphicsContext, center: CGPoint, size: CGFloat) {
        var p = Path()
        p.move(to: CGPoint(x: center.x - size*0.1, y: center.y - size*0.5))
        p.addLine(to: CGPoint(x: center.x + size*0.25, y: center.y - size*0.5))
        p.addLine(to: CGPoint(x: center.x, y: center.y))
        p.addLine(to: CGPoint(x: center.x + size*0.3, y: center.y))
        p.addLine(to: CGPoint(x: center.x - size*0.2, y: center.y + size*0.6))
        p.addLine(to: CGPoint(x: center.x + size*0.05, y: center.y + size*0.05))
        p.addLine(to: CGPoint(x: center.x - size*0.25, y: center.y + size*0.05))
        p.closeSubpath()
        ctx.fill(p, with: .color(.yellow))
        ctx.stroke(p, with: .color(.orange), lineWidth: 1)
    }

    private func drawFog(ctx: inout GraphicsContext, size: CGSize) {
        for i in 0..<4 {
            let y = size.height * (0.4 + CGFloat(i) * 0.12)
            let rect = CGRect(x: size.width*0.1, y: y, width: size.width*0.8, height: size.height*0.05)
            ctx.fill(Path(roundedRect: rect, cornerRadius: rect.height/2),
                     with: .color(Color(white: 0.85, opacity: 0.8)))
        }
    }
}
