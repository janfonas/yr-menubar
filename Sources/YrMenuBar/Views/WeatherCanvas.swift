import SwiftUI

/// Renders animated weather illustrations using SwiftUI Canvas based on a met.no symbol_code.
/// Inspired by yr.no's iOS app: subtle motion across all conditions — sun rays
/// rotate and twinkle, clouds drift, rain falls with depth, snow sways,
/// lightning flashes the whole scene.
struct WeatherCanvas: View {
    let symbolCode: String?
    /// When true: ~30fps. When false: ~6fps (still moves, very low CPU — fine for the 7-day list).
    var animated: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / (animated ? Constants.canvasAnimatedFps
                                                                  : Constants.canvasStaticFps))) { context in
            Canvas(rendersAsynchronously: true) { ctx, size in
                draw(ctx: &ctx, size: size, time: context.date.timeIntervalSinceReferenceDate)
            }
        }
        .accessibilityLabel(Text(symbolCode ?? "weather"))
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

        // Background flash for thunder (~once every 2.5s)
        var flashAlpha: Double = 0
        if hasThunder {
            let cycle = time.truncatingRemainder(dividingBy: 2.5)
            if cycle < 0.25 {
                flashAlpha = 0.55 * (1 - cycle / 0.25)
            }
        }

        // Sun or Moon
        if hasSun {
            let sunCenter = hasCloud
                ? CGPoint(x: center.x - s * 0.18, y: center.y - s * 0.18)
                : center
            let sunRadius = s * (hasCloud ? 0.18 : 0.28)
            if isNight || isPolar {
                drawMoon(ctx: &ctx, center: sunCenter, radius: sunRadius,
                         time: time, drawStars: !hasCloud, size: size)
            } else {
                drawSun(ctx: &ctx, center: sunCenter, radius: sunRadius, time: time)
            }
        }

        if hasFog {
            drawFog(ctx: &ctx, size: size, time: time)
        }

        if hasCloud {
            let drift = CGFloat(sin(time * 0.4)) * s * 0.015
            drawCloud(ctx: &ctx,
                      center: CGPoint(x: center.x + (hasSun ? s*0.05 : 0) + drift,
                                      y: center.y - s*0.02),
                      scale: s * (isHeavyCloud ? 0.55 : 0.45),
                      dark: isHeavyCloud)
            if base == "partlycloudy" {
                let drift2 = CGFloat(sin(time * 0.3 + 1.2)) * s * 0.02
                drawCloud(ctx: &ctx,
                          center: CGPoint(x: center.x + s*0.18 + drift2, y: center.y + s*0.05),
                          scale: s * 0.28, dark: false)
            }
        }

        if hasRain {
            drawRain(ctx: &ctx, center: CGPoint(x: center.x, y: center.y + s*0.18),
                     width: s * 0.5,
                     density: isHeavy ? 11 : (isLight ? 4 : 7),
                     time: time)
        }
        if hasSnow {
            drawSnow(ctx: &ctx, center: CGPoint(x: center.x, y: center.y + s*0.18),
                     width: s * 0.5,
                     count: isHeavy ? 8 : (isLight ? 3 : 5),
                     time: time)
        }
        if hasThunder {
            drawBolt(ctx: &ctx, center: CGPoint(x: center.x + s*0.05, y: center.y + s*0.12),
                     size: s * 0.28, time: time)
        }

        if flashAlpha > 0 {
            ctx.blendMode = .plusLighter
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(.white.opacity(flashAlpha)))
            ctx.blendMode = .normal
        }
    }

    // MARK: - Sun (rotating rays + twinkle pulse + glow)
    private func drawSun(ctx: inout GraphicsContext, center: CGPoint, radius: CGFloat, time: TimeInterval) {
        let rotation = time * 0.25
        let pulse = 0.5 + 0.5 * sin(time * 2)
        let rayLen = radius * (1.5 + 0.08 * pulse)
        let rays = Path { p in
            for i in 0..<8 {
                let a = (Double(i) / 8) * .pi * 2 + rotation
                let inner = CGPoint(x: center.x + cos(a) * radius * 1.18,
                                    y: center.y + sin(a) * radius * 1.18)
                let outer = CGPoint(x: center.x + cos(a) * rayLen,
                                    y: center.y + sin(a) * rayLen)
                p.move(to: inner)
                p.addLine(to: outer)
            }
        }
        ctx.stroke(rays, with: .color(Color.orange.opacity(0.65 + 0.35 * pulse)),
                   lineWidth: max(2, radius * 0.13))

        // Soft glow halo
        let glowRect = CGRect(x: center.x - radius*1.6, y: center.y - radius*1.6,
                              width: radius*3.2, height: radius*3.2)
        ctx.fill(Path(ellipseIn: glowRect),
                 with: .radialGradient(
                    Gradient(colors: [Color.yellow.opacity(0.25 * (0.5 + 0.5 * pulse)), .clear]),
                    center: center, startRadius: radius * 0.6, endRadius: radius * 1.6))

        let body = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                          width: radius*2, height: radius*2))
        ctx.fill(body, with: .radialGradient(
            Gradient(colors: [Color.yellow, Color.orange]),
            center: CGPoint(x: center.x - radius*0.3, y: center.y - radius*0.3),
            startRadius: 0, endRadius: radius * 1.2))
    }

    // MARK: - Moon (with twinkling stars when no clouds)
    private func drawMoon(ctx: inout GraphicsContext, center: CGPoint, radius: CGFloat,
                          time: TimeInterval, drawStars: Bool, size: CGSize) {
        if drawStars {
            let positions: [(CGFloat, CGFloat, Double)] = [
                (0.15, 0.15, 0.0), (0.85, 0.20, 1.3), (0.78, 0.55, 0.7),
                (0.30, 0.75, 2.1), (0.65, 0.78, 1.6), (0.12, 0.60, 0.4),
                (0.50, 0.18, 2.7), (0.92, 0.42, 1.0)
            ]
            for (rx, ry, offset) in positions {
                let twinkle = 0.5 + 0.5 * sin(time * 3 + offset)
                let r = max(1.0, size.width * 0.012)
                let p = CGPoint(x: size.width * rx, y: size.height * ry)
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r*2, height: r*2)),
                         with: .color(.white.opacity(0.4 + 0.6 * twinkle)))
            }
        }

        let full = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                          width: radius*2, height: radius*2))
        ctx.fill(full, with: .radialGradient(
            Gradient(colors: [Color(white: 1.0), Color(white: 0.85)]),
            center: CGPoint(x: center.x - radius*0.3, y: center.y - radius*0.3),
            startRadius: 0, endRadius: radius * 1.2))
        let cutout = Path(ellipseIn: CGRect(x: center.x - radius*0.35,
                                            y: center.y - radius*1.05,
                                            width: radius*2, height: radius*2))
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

    // MARK: - Rain (per-drop speed, gradient, alpha fade at top/bottom)
    private func drawRain(ctx: inout GraphicsContext, center: CGPoint, width: CGFloat,
                          density: Int, time: TimeInterval) {
        let dropLen = width * 0.14
        let lineW = max(1.5, width * 0.025)
        for i in 0..<density {
            let t = Double(i) / Double(density)
            let baseX = center.x - width/2 + width * CGFloat(t) + width * 0.03
            let speed = 1.3 + 0.5 * sin(Double(i) * 1.7)
            let phase = ((time * speed) + Double(i) * 0.37).truncatingRemainder(dividingBy: 1.0)
            let y = center.y - dropLen + dropLen * 2.2 * CGFloat(phase)
            let alpha = sin(.pi * phase)
            var p = Path()
            p.move(to: CGPoint(x: baseX, y: y))
            p.addLine(to: CGPoint(x: baseX - dropLen*0.25, y: y + dropLen))
            ctx.stroke(p,
                       with: .linearGradient(
                        Gradient(colors: [Color.cyan.opacity(0.2 + 0.6 * alpha),
                                          Color.blue.opacity(0.4 + 0.5 * alpha)]),
                        startPoint: CGPoint(x: baseX, y: y),
                        endPoint: CGPoint(x: baseX, y: y + dropLen)),
                       lineWidth: lineW)
        }
    }

    // MARK: - Snow (drift + sway + per-flake fade)
    private func drawSnow(ctx: inout GraphicsContext, center: CGPoint, width: CGFloat,
                          count: Int, time: TimeInterval) {
        for i in 0..<count {
            let t = Double(i) / Double(count)
            let baseX = center.x - width/2 + width * CGFloat(t) + width*0.05
            let speed = 0.4 + 0.2 * sin(Double(i) * 2.1)
            let phase = ((time * speed) + Double(i) * 0.41).truncatingRemainder(dividingBy: 1.0)
            let sway = CGFloat(sin(time * 1.0 + Double(i))) * width * 0.03
            let x = baseX + sway
            let y = center.y - width*0.15 + width*0.35 * CGFloat(phase)
            let r = width * 0.045
            let alpha = sin(.pi * phase)
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r*2, height: r*2)),
                     with: .color(.white.opacity(0.6 + 0.4 * alpha)))
            var arms = Path()
            arms.move(to: CGPoint(x: x - r*1.5, y: y)); arms.addLine(to: CGPoint(x: x + r*1.5, y: y))
            arms.move(to: CGPoint(x: x, y: y - r*1.5)); arms.addLine(to: CGPoint(x: x, y: y + r*1.5))
            ctx.stroke(arms, with: .color(Color(white: 0.95).opacity(0.5 + 0.5 * alpha)),
                       lineWidth: 1)
        }
    }

    // MARK: - Lightning bolt with bright flicker
    private func drawBolt(ctx: inout GraphicsContext, center: CGPoint, size: CGFloat, time: TimeInterval) {
        let cycle = time.truncatingRemainder(dividingBy: 2.5)
        let intensity: Double = cycle < 0.5 ? (1.0 - cycle / 0.5) : 0.25
        var p = Path()
        p.move(to: CGPoint(x: center.x - size*0.1, y: center.y - size*0.5))
        p.addLine(to: CGPoint(x: center.x + size*0.25, y: center.y - size*0.5))
        p.addLine(to: CGPoint(x: center.x, y: center.y))
        p.addLine(to: CGPoint(x: center.x + size*0.3, y: center.y))
        p.addLine(to: CGPoint(x: center.x - size*0.2, y: center.y + size*0.6))
        p.addLine(to: CGPoint(x: center.x + size*0.05, y: center.y + size*0.05))
        p.addLine(to: CGPoint(x: center.x - size*0.25, y: center.y + size*0.05))
        p.closeSubpath()
        ctx.fill(p, with: .color(Color.yellow.opacity(0.5 + 0.5 * intensity)))
        ctx.stroke(p, with: .color(Color.orange.opacity(0.6 + 0.4 * intensity)),
                   lineWidth: 1)
    }

    // MARK: - Fog (drifting bands)
    private func drawFog(ctx: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        for i in 0..<4 {
            let drift = CGFloat(sin(time * 0.4 + Double(i) * 1.1)) * size.width * 0.05
            let y = size.height * (0.4 + CGFloat(i) * 0.12)
            let rect = CGRect(x: size.width*0.1 + drift, y: y,
                              width: size.width*0.8, height: size.height*0.05)
            ctx.fill(Path(roundedRect: rect, cornerRadius: rect.height/2),
                     with: .color(Color(white: 0.85, opacity: 0.7)))
        }
    }
}
