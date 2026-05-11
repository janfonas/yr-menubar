import SwiftUI

/// Sheet shown from the Now-tab triangle button when one or more weather
/// alerts cover the active location.
struct AlertsView: View {
    let alerts: [WeatherAlert]
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(WeatherAlertStyle.headerColor(for: alerts))
                Text(L10n.t(.weatherAlerts))
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            if alerts.isEmpty {
                Text(L10n.t(.noAlerts))
                    .foregroundStyle(.secondary)
                    .padding(24)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(alerts) { alert in
                            AlertRow(alert: alert)
                            if alert.id != alerts.last?.id { Divider() }
                        }
                    }
                    .padding(14)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
        )
        .padding(8)
    }
}

private struct AlertRow: View {
    let alert: WeatherAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: WeatherAlertStyle.iconName(for: alert))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(WeatherAlertStyle.color(for: alert))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.headline)
                        .font(.subheadline.weight(.semibold))
                    if let area = alert.area, !area.isEmpty {
                        Text(area)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let color = alert.riskMatrixColor {
                    Text(color.uppercased())
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(WeatherAlertStyle.color(for: alert).opacity(0.18))
                        )
                        .foregroundStyle(WeatherAlertStyle.color(for: alert))
                }
            }

            if let desc = alert.description, !desc.isEmpty {
                Text(desc)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let inst = alert.instruction, !inst.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.t(.alertInstruction))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(inst)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let cons = alert.consequences, !cons.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.t(.alertConsequences))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(cons)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let url = alert.web {
                Link(L10n.t(.readMore), destination: url)
                    .font(.caption.weight(.medium))
                    .padding(.top, 2)
            }
        }
    }
}

/// Shared icon + colour mapping for MetAlerts.
enum WeatherAlertStyle {
    static func color(for alert: WeatherAlert) -> Color {
        switch (alert.riskMatrixColor ?? "").lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return Color(red: 0.92, green: 0.74, blue: 0.10)
        default: return .secondary
        }
    }

    static func headerColor(for alerts: [WeatherAlert]) -> Color {
        guard let worst = alerts.max(by: { $0.severityRank < $1.severityRank }) else {
            return .secondary
        }
        return color(for: worst)
    }

    /// Pick an SF Symbol that roughly matches the CAP `event` value.
    static func iconName(for alert: WeatherAlert) -> String {
        switch (alert.event ?? "").lowercased() {
        case "forestfire": return "flame.fill"
        case "blowingsnow", "snow": return "cloud.snow.fill"
        case "rain", "rainflood": return "cloud.rain.fill"
        case "lightning": return "cloud.bolt.rain.fill"
        case "wind", "gale", "polarlow": return "wind"
        case "ice", "icing": return "snowflake"
        case "stormsurge": return "water.waves"
        default: return "exclamationmark.triangle.fill"
        }
    }
}
