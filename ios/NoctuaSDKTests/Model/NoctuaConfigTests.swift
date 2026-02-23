import XCTest
@testable import NoctuaSDK

class NoctuaConfigTests: XCTestCase {

    func testDecodeMinimalConfig() {
        let json = """
        {"clientId": "test-client"}
        """
        let data = json.data(using: .utf8)!
        let config = try! JSONDecoder().decode(NoctuaConfig.self, from: data)

        XCTAssertEqual(config.clientId, "test-client")
        XCTAssertNil(config.gameId)
        XCTAssertNil(config.noctua)
        XCTAssertNil(config.adjust)
        XCTAssertNil(config.firebase)
        XCTAssertNil(config.facebook)
    }

    func testDecodeWithGameId() {
        let json = """
        {"clientId": "test-client", "gameId": 42}
        """
        let data = json.data(using: .utf8)!
        let config = try! JSONDecoder().decode(NoctuaConfig.self, from: data)

        XCTAssertEqual(config.clientId, "test-client")
        XCTAssertEqual(config.gameId, 42)
    }

    func testDecodeWithNoctuaServiceConfig() {
        let json = """
        {"clientId": "test-client", "noctua": {"nativeInternalTrackerEnabled": true, "iapDisabled": false}}
        """
        let data = json.data(using: .utf8)!
        let config = try! JSONDecoder().decode(NoctuaConfig.self, from: data)

        XCTAssertEqual(config.noctua?.nativeInternalTrackerEnabled, true)
        XCTAssertEqual(config.noctua?.iapDisabled, false)
    }

    func testDecodeWithIapDisabledTrue() {
        let json = """
        {"clientId": "test-client", "noctua": {"iapDisabled": true}}
        """
        let data = json.data(using: .utf8)!
        let config = try! JSONDecoder().decode(NoctuaConfig.self, from: data)

        XCTAssertEqual(config.noctua?.iapDisabled, true)
        XCTAssertNil(config.noctua?.nativeInternalTrackerEnabled)
    }

    func testDecodeMissingClientIdThrows() {
        let json = """
        {"gameId": 1}
        """
        let data = json.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(NoctuaConfig.self, from: data))
    }

    func testDecodeInvalidJsonThrows() {
        let json = "not valid json"
        let data = json.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(NoctuaConfig.self, from: data))
    }

    func testDecodeWithAdjustConfig() {
        let json = """
        {"clientId": "test", "adjust": {"ios": {"appToken": "abc123", "environment": "sandbox", "eventMap": {"purchase": "ev001"}}}}
        """
        let data = json.data(using: .utf8)!
        let config = try! JSONDecoder().decode(NoctuaConfig.self, from: data)

        XCTAssertEqual(config.adjust?.ios?.appToken, "abc123")
        XCTAssertEqual(config.adjust?.ios?.environment, "sandbox")
        XCTAssertEqual(config.adjust?.ios?.eventMap?["purchase"], "ev001")
    }

    func testDecodeWithFirebaseConfig() {
        let json = """
        {"clientId": "test", "firebase": {"ios": {"customEventDisabled": true}}}
        """
        let data = json.data(using: .utf8)!
        let config = try! JSONDecoder().decode(NoctuaConfig.self, from: data)

        XCTAssertEqual(config.firebase?.ios?.customEventDisabled, true)
    }

    func testDecodeFullConfig() {
        let json = """
        {
            "clientId": "full-client",
            "gameId": 99,
            "noctua": {"nativeInternalTrackerEnabled": true, "iapDisabled": false},
            "adjust": {"ios": {"appToken": "token123"}},
            "firebase": {"ios": {"customEventDisabled": false}},
            "facebook": {"ios": {"appId": "fb-app", "clientToken": "fb-token", "displayName": "Test App"}}
        }
        """
        let data = json.data(using: .utf8)!
        let config = try! JSONDecoder().decode(NoctuaConfig.self, from: data)

        XCTAssertEqual(config.clientId, "full-client")
        XCTAssertEqual(config.gameId, 99)
        XCTAssertNotNil(config.noctua)
        XCTAssertNotNil(config.adjust)
        XCTAssertNotNil(config.firebase)
        XCTAssertNotNil(config.facebook)
        XCTAssertEqual(config.facebook?.ios?.appId, "fb-app")
        XCTAssertEqual(config.facebook?.ios?.clientToken, "fb-token")
        XCTAssertEqual(config.facebook?.ios?.displayName, "Test App")
    }
}
