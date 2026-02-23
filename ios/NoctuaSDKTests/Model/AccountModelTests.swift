import XCTest
@testable import NoctuaSDK

class AccountModelTests: XCTestCase {

    func testAccountDefaultTimestamp() {
        let before = Int64(Date().timeIntervalSince1970 * 1000)
        let account = Account(playerId: 1, gameId: 2, rawData: "{}")
        let after = Int64(Date().timeIntervalSince1970 * 1000)

        XCTAssertEqual(account.playerId, 1)
        XCTAssertEqual(account.gameId, 2)
        XCTAssertEqual(account.rawData, "{}")
        XCTAssertGreaterThanOrEqual(account.lastUpdated, before)
        XCTAssertLessThanOrEqual(account.lastUpdated, after)
    }

    func testAccountExplicitTimestamp() {
        let account = Account(playerId: 10, gameId: 20, rawData: "data", lastUpdated: 1700000000)

        XCTAssertEqual(account.playerId, 10)
        XCTAssertEqual(account.gameId, 20)
        XCTAssertEqual(account.rawData, "data")
        XCTAssertEqual(account.lastUpdated, 1700000000)
    }

    func testAccountEncodable() {
        let account = Account(playerId: 5, gameId: 10, rawData: "test", lastUpdated: 999)
        let data = try! JSONEncoder().encode(account)
        let dict = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["playerId"] as? Int64, 5)
        XCTAssertEqual(dict["gameId"] as? Int64, 10)
        XCTAssertEqual(dict["rawData"] as? String, "test")
        XCTAssertEqual(dict["lastUpdated"] as? Int64, 999)
    }

    func testAccountPropertiesStored() {
        let account = Account(playerId: 100, gameId: 200, rawData: "{\"level\":5}")

        XCTAssertEqual(account.playerId, 100)
        XCTAssertEqual(account.gameId, 200)
        XCTAssertEqual(account.rawData, "{\"level\":5}")
    }
}
