import SwiftUI

/// Small "About" window surfaced from the menu-bar right-click menu. Shows the
/// app icon, name, version and a link to the public source repository.
struct AboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    private var copyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
            ?? "© Norwegian Meteorological Institute (MET Norway)."
    }

    var body: some View {
        VStack(spacing: 14) {
            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 84, height: 84)
            } else {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
            }

            VStack(spacing: 4) {
                Text("YrMenuBar")
                    .font(.title2.weight(.semibold))
                Text("v\(version)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Link(L10n.t(.viewOnGitHub), destination: Constants.repositoryURL)
                .font(.callout.weight(.medium))

            Text(copyright)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(width: 320)
    }
}
