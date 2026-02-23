import XCTest
@testable import NoctuaSDK

class AccountPresenterTests: XCTestCase {

    var mockRepo: MockAccountRepository!
    var logger: MockNoctuaLogger!
    var presenter: AccountPresenter!

    override func setUp() {
        super.setUp()
        mockRepo = MockAccountRepository()
        logger = MockNoctuaLogger()
        presenter = AccountPresenter(accountRepo: mockRepo, logger: logger)
    }

    func testPutAccount() {
        presenter.putAccount(gameId: 1, playerId: 100, rawData: "{\"name\":\"test\"}")

        XCTAssertEqual(mockRepo.putCalls.count, 1)
        XCTAssertEqual(mockRepo.putCalls[0].gameId, 1)
        XCTAssertEqual(mockRepo.putCalls[0].playerId, 100)
        XCTAssertEqual(mockRepo.putCalls[0].rawData, "{\"name\":\"test\"}")
    }

    func testGetAllAccountsEmpty() {
        let accounts = presenter.getAllAccounts()
        XCTAssertEqual(accounts.count, 0)
    }

    func testGetAllAccountsMappedCorrectly() {
        mockRepo.accounts = [
            Account(playerId: 1, gameId: 10, rawData: "data1", lastUpdated: 1000),
            Account(playerId: 2, gameId: 20, rawData: "data2", lastUpdated: 2000)
        ]

        let accounts = presenter.getAllAccounts()

        XCTAssertEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0]["playerId"] as? Int64, 1)
        XCTAssertEqual(accounts[0]["gameId"] as? Int64, 10)
        XCTAssertEqual(accounts[0]["rawData"] as? String, "data1")
        XCTAssertEqual(accounts[0]["lastUpdated"] as? Int64, 1000)

        XCTAssertEqual(accounts[1]["playerId"] as? Int64, 2)
        XCTAssertEqual(accounts[1]["gameId"] as? Int64, 20)
    }

    func testGetSingleAccountExisting() {
        mockRepo.accounts = [
            Account(playerId: 5, gameId: 10, rawData: "found", lastUpdated: 3000)
        ]

        let result = presenter.getSingleAccount(gameId: 10, playerId: 5)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?["playerId"] as? Int64, 5)
        XCTAssertEqual(result?["gameId"] as? Int64, 10)
        XCTAssertEqual(result?["rawData"] as? String, "found")
        XCTAssertEqual(result?["lastUpdated"] as? Int64, 3000)
    }

    func testGetSingleAccountNotFound() {
        let result = presenter.getSingleAccount(gameId: 999, playerId: 999)
        XCTAssertNil(result)
    }

    func testDeleteAccount() {
        presenter.deleteAccount(gameId: 1, playerId: 100)

        XCTAssertEqual(mockRepo.deleteCalls.count, 1)
        XCTAssertEqual(mockRepo.deleteCalls[0].0, 1)
        XCTAssertEqual(mockRepo.deleteCalls[0].1, 100)
    }

    func testPutAccountTwiceSameIdsUpdates() {
        presenter.putAccount(gameId: 1, playerId: 100, rawData: "old")
        presenter.putAccount(gameId: 1, playerId: 100, rawData: "new")

        XCTAssertEqual(mockRepo.putCalls.count, 2)
        // The mock repo replaces on same IDs
        XCTAssertEqual(mockRepo.accounts.count, 1)
        XCTAssertEqual(mockRepo.accounts[0].rawData, "new")
    }

    func testGetAllAccountsDictKeys() {
        mockRepo.accounts = [Account(playerId: 1, gameId: 1, rawData: "x", lastUpdated: 0)]

        let accounts = presenter.getAllAccounts()
        let keys = Set(accounts[0].keys)

        XCTAssertEqual(keys, Set(["playerId", "gameId", "rawData", "lastUpdated"]))
    }
}
