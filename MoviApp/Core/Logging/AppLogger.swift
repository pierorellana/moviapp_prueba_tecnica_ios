import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "MoviApp"

    static let network = Logger(subsystem: subsystem, category: "Network")
    static let authentication = Logger(subsystem: subsystem, category: "Authentication")

    static func networkInfo(_ message: String) {
        network.info("\(message, privacy: .public)")
        printInDebug(message)
    }

    static func networkError(_ message: String) {
        network.error("\(message, privacy: .public)")
        printInDebug(message)
    }

    private static func printInDebug(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}
