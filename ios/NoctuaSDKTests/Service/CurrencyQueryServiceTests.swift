import XCTest
import StoreKit
@testable import NoctuaSDK

class CurrencyQueryServiceTests: XCTestCase {

    var logger: MockNoctuaLogger!
    var service: CurrencyQueryService!

    override func setUp() {
        super.setUp()
        logger = MockNoctuaLogger()
        service = CurrencyQueryService(logger: logger)
    }

    func testGetActiveCurrencyStoresCallback() {
        // We can't easily test the full SKProductsRequest flow in unit tests
        // since it requires App Store connectivity. Instead, verify the service
        // accepts the call without crashing and logs appropriately.
        let expectation = XCTestExpectation(description: "callback stored")
        expectation.isInverted = true // We don't expect completion in unit tests

        service.getActiveCurrency(productId: "com.test.product") { _, _ in
            expectation.fulfill()
        }

        // Verify debug log was emitted
        XCTAssertTrue(logger.debugMessages.contains("Started currency query for product: com.test.product"))

        // Wait briefly to confirm callback is NOT called (no actual network)
        wait(for: [expectation], timeout: 0.5)
    }

    func testMultipleConcurrentRequests() {
        // Verify multiple requests can be queued without crashing
        service.getActiveCurrency(productId: "product1") { _, _ in }
        service.getActiveCurrency(productId: "product2") { _, _ in }

        XCTAssertEqual(logger.debugMessages.filter { $0.contains("Started currency query") }.count, 2)
    }

    func testServiceIsNSObject() {
        // CurrencyQueryService must be NSObject subclass for SKProductsRequestDelegate
        XCTAssertTrue(service is NSObject)
    }

    func testServiceConformsToDelegate() {
        // Verify it conforms to SKProductsRequestDelegate
        XCTAssertTrue(service is SKProductsRequestDelegate)
    }
}
