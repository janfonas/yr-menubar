import SwiftUI
import AppKit

/// Renders the status-bar icon as an `NSImage`, used by the custom
/// `StatusItemController`. Mirrors the previous SwiftUI `MenuBarLabel`:
/// a plain template SF Symbol when there are no warnings, or a coloured
/// badge composite when warnings are active.
enum MenuBarIcon {
    /// Build the status-item image for the given weather symbol + alert state.
    @MainActor
    static func image(symbolCode: String?, hasAlerts: Bool, worstSeverityRank: Int) -> NSImage? {
        let symbolName = SFSymbol.from(symbolCode: symbolCode)
        if !hasAlerts {
            // Template image so macOS tints it for light/dark menu bars.
            let img = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Weather")
            img?.isTemplate = true
            return img
        }
        return renderBadge(weatherSymbol: symbolName, tint: badgeColor(rank: worstSeverityRank))
            ?? {
                let fallback = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Weather")
                fallback?.isTemplate = true
                return fallback
            }()
    }

    private static func badgeColor(rank: Int) -> Color {
        switch rank {
        case 3: return .red
        case 2: return .orange
        default: return Color(red: 0.96, green: 0.80, blue: 0.13)
        }
    }

    @MainActor
    private static func renderBadge(weatherSymbol: String, tint: Color) -> NSImage? {
        let canvasSize = CGSize(width: 28, height: 22)
        let view = ZStack(alignment: .topTrailing) {
            Image(systemName: weatherSymbol)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Color(NSColor.labelColor))
                .font(.system(size: 16, weight: .regular))
                .frame(width: 22, height: 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.top, 2)
            Image(systemName: "exclamationmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, tint)
                .font(.system(size: 11, weight: .black))
                .padding(.top, 1)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)

        let renderer = ImageRenderer(content: view)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        guard let nsImage = renderer.nsImage else { return nil }
        nsImage.isTemplate = false
        return nsImage
    }
}
