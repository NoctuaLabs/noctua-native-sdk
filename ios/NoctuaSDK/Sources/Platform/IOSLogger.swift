import Foundation
import os

class IOSLogger: NoctuaLogger {
    private let logger: os.Logger

    init(category: String) {
        self.logger = os.Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: category
        )
    }

    func debug(_ message: String) {
        logger.debug("\(message)")
    }

    func info(_ message: String) {
        logger.info("\(message)")
    }

    func warning(_ message: String) {
        logger.warning("\(message)")
    }

    func error(_ message: String) {
        logger.error("\(message)")
    }
}
