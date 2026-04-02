import Foundation
import os

class IOSLogger: NoctuaLogger {
    private let logger: os.Logger

    /// When false, only error() logs are emitted; debug/info/warning are suppressed.
    var isEnabled: Bool = true

    init(category: String) {
        self.logger = os.Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: category
        )
    }

    func debug(_ message: String) {
        guard isEnabled else { return }
        logger.debug("\(message)")
    }

    func info(_ message: String) {
        guard isEnabled else { return }
        logger.info("\(message)")
    }

    func warning(_ message: String) {
        guard isEnabled else { return }
        logger.warning("\(message)")
    }

    func error(_ message: String) {
        logger.error("\(message)")
    }
}
