import SwiftUI

/// Atmospheric background gradient based on a met.no symbol_code.
/// Mimics yr.no's app where the sky color reflects current conditions.
struct SkyBackground: View {
    let symbolCode: String?

    var body: some View {
        LinearGradient(colors: colors,
                       startPoint: .top,
                       endPoint: .bottom)
            .ignoresSafeArea()
    }

    private var colors: [Color] {
        let code = symbolCode ?? "cloudy"
        let isNight = code.contains("_night")
        let base = code
            .replacingOccurrences(of: "_day", with: "")
            .replacingOccurrences(of: "_night", with: "")
            .replacingOccurrences(of: "_polartwilight", with: "")

        if isNight {
            switch base {
            case "clearsky", "fair":
                return [Color(red: 0.04, green: 0.07, blue: 0.18),
                        Color(red: 0.09, green: 0.14, blue: 0.30)]
            case "partlycloudy":
                return [Color(red: 0.07, green: 0.10, blue: 0.22),
                        Color(red: 0.14, green: 0.20, blue: 0.34)]
            default:
                return [Color(red: 0.10, green: 0.13, blue: 0.20),
                        Color(red: 0.18, green: 0.22, blue: 0.30)]
            }
        }

        switch base {
        case "clearsky":
            return [Color(red: 0.30, green: 0.55, blue: 0.85),
                    Color(red: 0.55, green: 0.78, blue: 0.95)]
        case "fair", "partlycloudy":
            return [Color(red: 0.32, green: 0.55, blue: 0.82),
                    Color(red: 0.65, green: 0.80, blue: 0.92)]
        case "cloudy":
            return [Color(red: 0.42, green: 0.52, blue: 0.62),
                    Color(red: 0.65, green: 0.72, blue: 0.78)]
        case "fog":
            return [Color(red: 0.62, green: 0.66, blue: 0.70),
                    Color(red: 0.78, green: 0.80, blue: 0.82)]
        case let s where s.contains("thunder"):
            return [Color(red: 0.22, green: 0.25, blue: 0.32),
                    Color(red: 0.38, green: 0.42, blue: 0.50)]
        case let s where s.contains("rain"):
            return [Color(red: 0.32, green: 0.42, blue: 0.55),
                    Color(red: 0.55, green: 0.65, blue: 0.74)]
        case let s where s.contains("snow") || s.contains("sleet"):
            return [Color(red: 0.55, green: 0.62, blue: 0.72),
                    Color(red: 0.78, green: 0.82, blue: 0.88)]
        default:
            return [Color(red: 0.40, green: 0.55, blue: 0.72),
                    Color(red: 0.65, green: 0.78, blue: 0.88)]
        }
    }
}
