import Foundation
@testable import NoctuaSDK

class MockNoctuaLogger: NoctuaLogger {
    var debugMessages: [String] = []
    var infoMessages: [String] = []
    var warningMessages: [String] = []
    var errorMessages: [String] = []

    func debug(_ message: String) { debugMessages.append(message) }
    func info(_ message: String) { infoMessages.append(message) }
    func warning(_ message: String) { warningMessages.append(message) }
    func error(_ message: String) { errorMessages.append(message) }

    func reset() {
        debugMessages.removeAll()
        infoMessages.removeAll()
        warningMessages.removeAll()
        errorMessages.removeAll()
    }
}
