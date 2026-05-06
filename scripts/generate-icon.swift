#!/usr/bin/env swift
// Generates Resources/AppIcon.icns by drawing a "sun behind cloud" on a
// rounded sky-blue tile at every size macOS requires, then assembling the
// iconset with `iconutil`.
//
// Run from the repo root:  swift scripts/generate-icon.swift
//
// Output:
//   Resources/AppIcon.icns
//   Resources/AppIcon.iconset/  (intermediate, kept for inspection)

import AppKit
import CoreGraphics
import Foundation

// MARK: - Geometry helpers

func roundedTile(in ctx: CGContext, size: CGFloat) {
    // Rounded square in the macOS Sequoia "squircle" style (~22.4% radius).
    let inset: CGFloat = size * 0.07
    let rect = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let radius = (size - 2 * inset) * 0.224
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

    // Sky-blue gradient
    let colors = [
        CGColor(red: 0.36, green: 0.65, blue: 0.93, alpha: 1.0),
        CGColor(red: 0.20, green: 0.48, blue: 0.82, alpha: 1.0)
    ] as CFArray
    guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: colors,
                                    locations: [0.0, 1.0]) else { return }
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: 0, y: 0),
                           options: [])
    ctx.restoreGState()
}

func drawSun(in ctx: CGContext, center: CGPoint, radius: CGFloat) {
    // Soft outer glow
    ctx.saveGState()
    let glowColors = [
        CGColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 0.55),
        CGColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 0.0)
    ] as CFArray
    if let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                             colors: glowColors,
                             locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(glow,
                               startCenter: center, startRadius: radius * 0.6,
                               endCenter: center,   endRadius: radius * 1.9,
                               options: [])
    }
    ctx.restoreGState()

    // Rays
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 1.0, green: 0.78, blue: 0.18, alpha: 1.0))
    ctx.setLineCap(.round)
    let rayCount = 8
    let rayInner = radius * 1.18
    let rayOuter = radius * 1.65
    let rayWidth = radius * 0.22
    ctx.setLineWidth(rayWidth)
    for i in 0..<rayCount {
        let angle = CGFloat(i) * (.pi * 2 / CGFloat(rayCount))
        let p1 = CGPoint(x: center.x + cos(angle) * rayInner,
                         y: center.y + sin(angle) * rayInner)
        let p2 = CGPoint(x: center.x + cos(angle) * rayOuter,
                         y: center.y + sin(angle) * rayOuter)
        ctx.move(to: p1)
        ctx.addLine(to: p2)
    }
    ctx.strokePath()
    ctx.restoreGState()

    // Sun disc
    ctx.saveGState()
    let sunColors = [
        CGColor(red: 1.0, green: 0.92, blue: 0.40, alpha: 1.0),
        CGColor(red: 1.0, green: 0.74, blue: 0.10, alpha: 1.0)
    ] as CFArray
    if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: sunColors,
                          locations: [0.0, 1.0]) {
        let bounds = CGRect(x: center.x - radius, y: center.y - radius,
                            width: radius * 2, height: radius * 2)
        ctx.addEllipse(in: bounds)
        ctx.clip()
        ctx.drawLinearGradient(g,
                               start: CGPoint(x: center.x, y: center.y + radius),
                               end:   CGPoint(x: center.x, y: center.y - radius),
                               options: [])
    }
    ctx.restoreGState()
}

func drawCloud(in ctx: CGContext, rect: CGRect) {
    // A chubby cloud built from four overlapping circles plus a low rounded
    // base so the silhouette has visible bumps along the top.
    let h = rect.height
    let w = rect.width

    let path = CGMutablePath()
    // Low flat base (≈30% of cloud height) anchored to the bottom of `rect`.
    let baseHeight = h * 0.32
    path.addRoundedRect(in: CGRect(x: rect.minX,
                                   y: rect.minY,
                                   width: w,
                                   height: baseHeight),
                        cornerWidth: baseHeight * 0.45,
                        cornerHeight: baseHeight * 0.45)

    // Big middle puff
    let bigD = h * 0.82
    path.addEllipse(in: CGRect(x: rect.minX + (w - bigD) / 2,
                               y: rect.minY + h * 0.18,
                               width: bigD, height: bigD))
    // Left puff (smaller)
    let leftD = h * 0.55
    path.addEllipse(in: CGRect(x: rect.minX - leftD * 0.05,
                               y: rect.minY + h * 0.05,
                               width: leftD, height: leftD))
    // Right puff (medium)
    let rightD = h * 0.62
    path.addEllipse(in: CGRect(x: rect.minX + w - rightD * 0.95,
                               y: rect.minY + h * 0.10,
                               width: rightD, height: rightD))

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -h * 0.04),
                  blur: h * 0.10,
                  color: CGColor(gray: 0.0, alpha: 0.30))

    let colors = [
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        CGColor(red: 0.84, green: 0.89, blue: 0.96, alpha: 1.0)
    ] as CFArray
    if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: colors,
                          locations: [0.0, 1.0]) {
        ctx.addPath(path)
        ctx.clip()
        ctx.drawLinearGradient(g,
                               start: CGPoint(x: 0, y: rect.maxY),
                               end:   CGPoint(x: 0, y: rect.minY),
                               options: [])
    }
    ctx.restoreGState()
}

// MARK: - Per-size renderer

func renderIcon(size: CGFloat) -> Data? {
    let intSize = Int(size)
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(data: nil,
                              width: intSize, height: intSize,
                              bitsPerComponent: 8,
                              bytesPerRow: 0,
                              space: cs,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        return nil
    }
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    // Background tile
    roundedTile(in: ctx, size: size)

    // The drawing area inside the rounded tile.
    let inset = size * 0.10
    let area = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)

    // Sun in the upper-left, partially behind the cloud.
    let sunRadius = area.width * 0.24
    let sunCenter = CGPoint(x: area.minX + area.width * 0.32,
                            y: area.minY + area.height * 0.72)
    drawSun(in: ctx, center: sunCenter, radius: sunRadius)

    // Cloud anchored across the bottom-right, overlapping the sun.
    let cloudRect = CGRect(x: area.minX + area.width * 0.22,
                           y: area.minY + area.height * 0.05,
                           width: area.width * 0.78,
                           height: area.height * 0.55)
    drawCloud(in: ctx, rect: cloudRect)

    guard let cgImage = ctx.makeImage() else { return nil }
    let bitmap = NSBitmapImageRep(cgImage: cgImage)
    return bitmap.representation(using: .png, properties: [:])
}

// MARK: - Iconset assembly

let fm = FileManager.default
let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
let resources = cwd.appendingPathComponent("Resources")
let iconset = resources.appendingPathComponent("AppIcon.iconset")
let icns = resources.appendingPathComponent("AppIcon.icns")

try? fm.removeItem(at: iconset)
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)

// macOS standard iconset sizes: 16, 32, 64, 128, 256, 512, 1024
struct IconVariant { let size: Int; let scale: Int; let label: String }
let variants: [IconVariant] = [
    .init(size: 16,   scale: 1, label: "icon_16x16.png"),
    .init(size: 16,   scale: 2, label: "icon_16x16@2x.png"),
    .init(size: 32,   scale: 1, label: "icon_32x32.png"),
    .init(size: 32,   scale: 2, label: "icon_32x32@2x.png"),
    .init(size: 128,  scale: 1, label: "icon_128x128.png"),
    .init(size: 128,  scale: 2, label: "icon_128x128@2x.png"),
    .init(size: 256,  scale: 1, label: "icon_256x256.png"),
    .init(size: 256,  scale: 2, label: "icon_256x256@2x.png"),
    .init(size: 512,  scale: 1, label: "icon_512x512.png"),
    .init(size: 512,  scale: 2, label: "icon_512x512@2x.png")
]

for v in variants {
    let pixels = CGFloat(v.size * v.scale)
    guard let data = renderIcon(size: pixels) else {
        FileHandle.standardError.write(Data("Failed to render \(v.label)\n".utf8))
        exit(1)
    }
    try data.write(to: iconset.appendingPathComponent(v.label))
    print("  wrote \(v.label) (\(Int(pixels))px)")
}

print("==> Assembling \(icns.path)")
let task = Process()
task.launchPath = "/usr/bin/iconutil"
task.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try task.run()
task.waitUntilExit()
if task.terminationStatus != 0 {
    FileHandle.standardError.write(Data("iconutil failed\n".utf8))
    exit(Int32(task.terminationStatus))
}
print("==> Done")
