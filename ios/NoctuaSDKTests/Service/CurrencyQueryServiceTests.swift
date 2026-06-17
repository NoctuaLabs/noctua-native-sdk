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
        // We can't test the full SKProductsRequest flow in unit tests (it needs App Store
        // connectivity, and StoreKit may complete/fail at non-deterministic timing — so we
        // must not assert on whether/when the callback fires). Instead, verify the service
        // accepts the call without crashing and synchronously logs the query start.
        service.getActiveCurrency(productId: "com.test.product") { _, _ in }

        XCTAssertTrue(logger.debugMessages.contains("Started currency query for product: com.test.product"))
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
