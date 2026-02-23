import XCTest
@testable import NoctuaSDK

class StoreKitPresenterTests: XCTestCase {

    var mockService: MockStoreKitService!
    var logger: MockNoctuaLogger!
    var presenter: StoreKitPresenter!

    override func setUp() {
        super.setUp()
        mockService = MockStoreKitService()
        logger = MockNoctuaLogger()
        presenter = StoreKitPresenter(storeKitService: mockService, logger: logger)
    }

    // MARK: - Initialization

    func testInitializeStoreKit() {
        presenter.initializeStoreKit()

        XCTAssertTrue(mockService.initializeCalled)
        XCTAssertNotNil(mockService.initializeListener)
        XCTAssertTrue(logger.infoMessages.contains("StoreKitPresenter initialized"))
    }

    func testInitializeStoreKitNilService() {
        let nilPresenter = StoreKitPresenter(storeKitService: nil, logger: logger)
        // Should not crash
        nilPresenter.initializeStoreKit()
        XCTAssertFalse(mockService.initializeCalled)
    }

    func testInitializeStoreKitStoresCallbacks() {
        var purchaseCompletedCalled = false
        var purchaseUpdatedCalled = false
        var productDetailsLoadedCalled = false
        var queryPurchasesCompletedCalled = false
        var storeKitErrorCalled = false

        presenter.initializeStoreKit(
            onPurchaseCompleted: { _ in purchaseCompletedCalled = true },
            onPurchaseUpdated: { _ in purchaseUpdatedCalled = true },
            onProductDetailsLoaded: { _ in productDetailsLoadedCalled = true },
            onQueryPurchasesCompleted: { _ in queryPurchasesCompletedCalled = true },
            onStoreKitError: { _, _ in storeKitErrorCalled = true }
        )

        // Trigger callbacks via the bridge (captured listener)
        let listener = mockService.initializeListener!

        let result = NoctuaPurchaseResult(success: true)
        listener.onPurchaseCompleted(result: result)
        XCTAssertTrue(purchaseCompletedCalled)

        listener.onPurchaseUpdated(result: result)
        XCTAssertTrue(purchaseUpdatedCalled)

        let details = NoctuaProductDetails(
            productId: "test", title: "Test", productDescription: "Desc",
            formattedPrice: "$1", priceAmountMicros: 1000000, priceCurrencyCode: "USD",
            productType: .inapp
        )
        listener.onProductDetailsLoaded(products: [details])
        XCTAssertTrue(productDetailsLoadedCalled)

        listener.onQueryPurchasesCompleted(purchases: [result])
        XCTAssertTrue(queryPurchasesCompletedCalled)

        listener.onStoreKitError(error: .error, message: "test error")
        XCTAssertTrue(storeKitErrorCalled)
    }

    func testBridgeRestorePurchasesCallback() {
        var restoreCalled = false

        presenter.initializeStoreKit(
            onRestorePurchasesCompleted: { _ in restoreCalled = true }
        )

        let listener = mockService.initializeListener!
        listener.onRestorePurchasesCompleted(purchases: [])
        XCTAssertTrue(restoreCalled)
    }

    func testBridgeProductPurchaseStatusCallback() {
        var statusResult: NoctuaProductPurchaseStatus?

        presenter.initializeStoreKit(
            onProductPurchaseStatusResult: { status in statusResult = status }
        )

        let listener = mockService.initializeListener!
        let status = NoctuaProductPurchaseStatus(productId: "test.product", isPurchased: true)
        listener.onProductPurchaseStatusResult(status: status)

        XCTAssertNotNil(statusResult)
        XCTAssertEqual(statusResult?.productId, "test.product")
        XCTAssertTrue(statusResult?.isPurchased ?? false)
    }

    func testBridgeServerVerificationCallback() {
        var verificationResult: NoctuaPurchaseResult?
        var verificationConsumableType: ConsumableType?

        presenter.initializeStoreKit(
            onServerVerificationRequired: { result, type in
                verificationResult = result
                verificationConsumableType = type
            }
        )

        let listener = mockService.initializeListener!
        let result = NoctuaPurchaseResult(success: true, productId: "com.test.item")
        listener.onServerVerificationRequired(result: result, consumableType: .consumable)

        XCTAssertNotNil(verificationResult)
        XCTAssertEqual(verificationResult?.productId, "com.test.item")
        XCTAssertEqual(verificationConsumableType, .consumable)
    }

    // MARK: - Product Registration & Query

    func testRegisterProduct() {
        presenter.registerProduct(productId: "com.test.product", consumableType: .consumable)

        XCTAssertEqual(mockService.registeredProducts.count, 1)
        XCTAssertEqual(mockService.registeredProducts[0].0, "com.test.product")
        XCTAssertEqual(mockService.registeredProducts[0].1, .consumable)
    }

    func testQueryProductDetails() {
        presenter.queryProductDetails(productIds: ["prod1", "prod2"], productType: .inapp)

        XCTAssertEqual(mockService.queryProductDetailsCalls.count, 1)
        XCTAssertEqual(mockService.queryProductDetailsCalls[0].0, ["prod1", "prod2"])
        XCTAssertEqual(mockService.queryProductDetailsCalls[0].1, .inapp)
    }

    func testQueryProductDetailsSubs() {
        presenter.queryProductDetails(productIds: ["sub1"], productType: .subs)

        XCTAssertEqual(mockService.queryProductDetailsCalls[0].1, .subs)
    }

    // MARK: - Purchase

    func testPurchase() {
        presenter.purchase(productId: "com.test.buy")

        XCTAssertEqual(mockService.purchaseCalls.count, 1)
        XCTAssertEqual(mockService.purchaseCalls[0], "com.test.buy")
        XCTAssertTrue(logger.debugMessages.contains("Purchase requested for: com.test.buy"))
    }

    // MARK: - Query & Restore

    func testQueryPurchases() {
        presenter.queryPurchases(productType: .inapp)

        XCTAssertEqual(mockService.queryPurchasesCalls.count, 1)
        XCTAssertEqual(mockService.queryPurchasesCalls[0], .inapp)
    }

    func testRestorePurchases() {
        presenter.restorePurchases()
        XCTAssertTrue(mockService.restorePurchasesCalled)
    }

    func testGetProductPurchaseStatus() {
        presenter.getProductPurchaseStatus(productId: "com.test.check")

        XCTAssertEqual(mockService.getProductPurchaseStatusCalls.count, 1)
        XCTAssertEqual(mockService.getProductPurchaseStatusCalls[0], "com.test.check")
    }

    // MARK: - Server Verification

    func testCompletePurchaseProcessing() {
        var callbackResult: Bool?
        presenter.completePurchaseProcessing(
            purchaseToken: "token-123",
            consumableType: .nonConsumable,
            verified: true,
            callback: { result in callbackResult = result }
        )

        XCTAssertEqual(mockService.completePurchaseProcessingCalls.count, 1)
        XCTAssertEqual(mockService.completePurchaseProcessingCalls[0].0, "token-123")
        XCTAssertEqual(mockService.completePurchaseProcessingCalls[0].1, .nonConsumable)
        XCTAssertEqual(mockService.completePurchaseProcessingCalls[0].2, true)
        XCTAssertEqual(callbackResult, true)
    }

    // MARK: - Lifecycle

    func testDisposeStoreKit() {
        presenter.initializeStoreKit()
        presenter.disposeStoreKit()

        XCTAssertTrue(mockService.disposeCalled)
    }

    func testIsStoreKitReadyTrue() {
        mockService.isReadyReturnValue = true
        XCTAssertTrue(presenter.isStoreKitReady())
    }

    func testIsStoreKitReadyFalse() {
        mockService.isReadyReturnValue = false
        XCTAssertFalse(presenter.isStoreKitReady())
    }

    func testIsStoreKitReadyNilService() {
        let nilPresenter = StoreKitPresenter(storeKitService: nil, logger: logger)
        XCTAssertFalse(nilPresenter.isStoreKitReady())
    }
}
