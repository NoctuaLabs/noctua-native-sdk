import XCTest
@testable import NoctuaSDK

class NoctuaErrorTests: XCTestCase {

    func testConfigurationErrorCases() {
        let fileNotFound = ConfigurationError.fileNotFound
        let invalidFormat = ConfigurationError.invalidFormat
        let missingKey = ConfigurationError.missingKey("clientId")
        let unknown = ConfigurationError.unknown(NSError(domain: "test", code: 1))

        // Verify they are distinct error cases
        switch fileNotFound {
        case .fileNotFound: break
        default: XCTFail("Expected fileNotFound")
        }

        switch invalidFormat {
        case .invalidFormat: break
        default: XCTFail("Expected invalidFormat")
        }

        switch missingKey {
        case .missingKey(let key):
            XCTAssertEqual(key, "clientId")
        default: XCTFail("Expected missingKey")
        }

        switch unknown {
        case .unknown(let error):
            XCTAssertEqual((error as NSError).domain, "test")
        default: XCTFail("Expected unknown")
        }
    }

    func testAdjustServiceErrorCases() {
        let notFound = AdjustServiceError.adjustNotFound
        let invalidConfig = AdjustServiceError.invalidConfig("missing token")

        switch notFound {
        case .adjustNotFound: break
        default: XCTFail("Expected adjustNotFound")
        }

        switch invalidConfig {
        case .invalidConfig(let message):
            XCTAssertEqual(message, "missing token")
        default: XCTFail("Expected invalidConfig")
        }
    }

    func testInitErrorCase() {
        let error = InitError.invalidArgument("bad input")

        switch error {
        case .invalidArgument(let message):
            XCTAssertEqual(message, "bad input")
        }
    }

    func testFirebaseServiceErrorCases() {
        let notFound = FirebaseServiceError.firebaseNotFound
        let invalidConfig = FirebaseServiceError.invalidConfig("missing config")

        switch notFound {
        case .firebaseNotFound: break
        default: XCTFail("Expected firebaseNotFound")
        }

        switch invalidConfig {
        case .invalidConfig(let message):
            XCTAssertEqual(message, "missing config")
        default: XCTFail("Expected invalidConfig")
        }
    }

    func testFacebookServiceErrorCases() {
        let notFound = FacebookServiceError.facebookNotFound
        let invalidConfig = FacebookServiceError.invalidConfig("missing appId")

        switch notFound {
        case .facebookNotFound: break
        default: XCTFail("Expected facebookNotFound")
        }

        switch invalidConfig {
        case .invalidConfig(let message):
            XCTAssertEqual(message, "missing appId")
        default: XCTFail("Expected invalidConfig")
        }
    }
}
