import Foundation
import os

/// Lightweight diagnostics helper. Messages are emitted through `os.Logger`
/// under the subsystem below so they can be captured live with:
///
///   log stream --predicate 'subsystem == "com.janfonas.YrMenuBar"' --info --debug
///
/// or after the fact with:
///
///   log show --last 10m --predicate 'subsystem == "com.janfonas.YrMenuBar"' --info --debug
///
enum Diag {
    static let subsystem = "com.janfonas.YrMenuBar"
    static let log = Logger(subsystem: subsystem, category: "general")
    static let location = Logger(subsystem: subsystem, category: "location")
}
