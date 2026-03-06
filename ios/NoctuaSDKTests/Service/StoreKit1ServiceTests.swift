import XCTest
import StoreKit
@testable import NoctuaSDK

// MARK: - Mock Event Listener

class MockStoreKitEventListener: StoreKitEventListener {
    var purchaseCompletedResults: [NoctuaPurchaseResult] = []
    var purchaseUpdatedResults: [NoctuaPurchaseResult] = []
    var productDetailsLoadedResults: [[NoctuaProductDetails]] = []
    var queryPurchasesCompletedResults: [[NoctuaPurchaseResult]] = []
    var restorePurchasesCompletedResults: [[NoctuaPurchaseResult]] = []
    var productPurchaseStatusResults: [NoctuaProductPurchaseStatus] = []
    var serverVerificationRequiredResults: [(NoctuaPurchaseResult, ConsumableType)] = []
    var storeKitErrors: [(StoreKitErrorCode, String)] = []

    func onPurchaseCompleted(result: NoctuaPurchaseResult) {
        purchaseCompletedResults.append(result)
    }

    func onPurchaseUpdated(result: NoctuaPurchaseResult) {
        purchaseUpdatedResults.append(result)
    }

    func onProductDetailsLoaded(products: [NoctuaProductDetails]) {
        productDetailsLoadedResults.append(products)
    }

    func onQueryPurchasesCompleted(purchases: [NoctuaPurchaseResult]) {
        queryPurchasesCompletedResults.append(purchases)
    }

    func onRestorePurchasesCompleted(purchases: [NoctuaPurchaseResult]) {
        restorePurchasesCompletedResults.append(purchases)
    }

    func onProductPurchaseStatusResult(status: NoctuaProductPurchaseStatus) {
        productPurchaseStatusResults.append(status)
    }

    func onServerVerificationRequired(result: NoctuaPurchaseResult, consumableType: ConsumableType) {
        serverVerificationRequiredResults.append((result, consumableType))
    }

    func onStoreKitError(error: StoreKitErrorCode, message: String) {
        storeKitErrors.append((error, message))
    }
}

// MARK: - Mock SKProductsRequest

class MockSKProductsRequest: SKProductsRequest {
    var startCalled = false
    var cancelCalled = false

    override func start() {
        startCalled = true
    }

    override func cancel() {
        cancelCalled = true
    }
}

// MARK: - StoreKit1ServiceTests

class StoreKit1ServiceTests: XCTestCase {

    var sut: StoreKit1Service!
    var mockQueue: MockPaymentQueue!
    var mockLogger: MockNoctuaLogger!
    var mockListener: MockStoreKitEventListener!
    var capturedRequests: [MockSKProductsRequest]!

    override func setUp() {
        super.setUp()
        mockQueue = MockPaymentQueue()
        mockLogger = MockNoctuaLogger()
        mockListener = MockStoreKitEventListener()
        capturedRequests = []

        let config = NoctuaStoreKitConfig(verifyPurchasesOnServer: false)
        sut = StoreKit1Service(
            config: config,
            logger: mockLogger,
            paymentQueue: mockQueue,
            productRequestFactory: { [weak self] identifiers in
                let request = MockSKProductsRequest(productIdentifiers: identifiers)
                self?.capturedRequests.append(request)
                return request
            }
        )
    }

    override func tearDown() {
        sut = nil
        mockQueue = nil
        mockLogger = nil
        mockListener = nil
        capturedRequests = nil
        super.tearDown()
    }

    // Helper: create service with server verification enabled
    private func makeServerVerifyService() -> StoreKit1Service {
        let config = NoctuaStoreKitConfig(verifyPurchasesOnServer: true)
        return StoreKit1Service(
            config: config,
            logger: mockLogger,
            paymentQueue: mockQueue,
            productRequestFactory: { [weak self] identifiers in
                let request = MockSKProductsRequest(productIdentifiers: identifiers)
                self?.capturedRequests.append(request)
                return request
            }
        )
    }

    // Helper: create a mock purchased transaction
    private func makePurchasedTransaction(productId: String, txId: String, date: Date = Date()) -> MockSKPaymentTransaction {
        let payment = MockSKPayment(productIdentifier: productId)
        return MockSKPaymentTransaction(
            payment: payment,
            transactionState: .purchased,
            transactionIdentifier: txId,
            transactionDate: date
        )
    }

    // Helper: create a mock failed transaction
    private func makeFailedTransaction(productId: String, error: Error) -> MockSKPaymentTransaction {
        let payment = MockSKPayment(productIdentifier: productId)
        return MockSKPaymentTransaction(
            payment: payment,
            transactionState: .failed,
            error: error
        )
    }

    // Helper: create a mock restored transaction
    private func makeRestoredTransaction(productId: String, txId: String, originalTxId: String) -> MockSKPaymentTransaction {
        let payment = MockSKPayment(productIdentifier: productId)
        let originalPayment = MockSKPayment(productIdentifier: productId)
        let original = MockSKPaymentTransaction(
            payment: originalPayment,
            transactionState: .purchased,
            transactionIdentifier: originalTxId
        )
        return MockSKPaymentTransaction(
            payment: payment,
            transactionState: .restored,
            transactionIdentifier: txId,
            original: original
        )
    }

    // Helper: create a mock deferred transaction
    private func makeDeferredTransaction(productId: String) -> MockSKPaymentTransaction {
        let payment = MockSKPayment(productIdentifier: productId)
        return MockSKPaymentTransaction(
            payment: payment,
            transactionState: .deferred
        )
    }

    // MARK: - Lifecycle Tests

    func testInitializeAddsObserver() {
        sut.initialize(listener: mockListener)

        XCTAssertTrue(mockQueue.addObserverCalled)
        XCTAssertEqual(mockQueue.addedObservers.count, 1)
    }

    func testInitializeSetsReady() {
        XCTAssertFalse(sut.isReady())

        sut.initialize(listener: mockListener)

        XCTAssertTrue(sut.isReady())
    }

    func testDoubleInitializeWarns() {
        sut.initialize(listener: mockListener)
        sut.initialize(listener: mockListener)

        XCTAssertEqual(mockQueue.addedObservers.count, 1, "Observer should only be added once")
        XCTAssertTrue(mockLogger.warningMessages.contains("StoreKit1Service already initialized"))
    }

    func testDisposeRemovesObserver() {
        sut.initialize(listener: mockListener)
        sut.dispose()

        XCTAssertTrue(mockQueue.removeObserverCalled)
        XCTAssertEqual(mockQueue.removedObservers.count, 1)
        XCTAssertFalse(sut.isReady())
    }

    func testIsReadyReflectsState() {
        XCTAssertFalse(sut.isReady())

        sut.initialize(listener: mockListener)
        XCTAssertTrue(sut.isReady())

        sut.dispose()
        XCTAssertFalse(sut.isReady())
    }

    // MARK: - Register Product Tests

    func testRegisterProductStoresType() {
        sut.registerProduct(productId: "com.test.consumable", consumableType: .consumable)
        sut.registerProduct(productId: "com.test.nonconsumable", consumableType: .nonConsumable)
        sut.registerProduct(productId: "com.test.subscription", consumableType: .subscription)

        XCTAssertTrue(mockLogger.debugMessages.contains(where: { $0.contains("com.test.consumable") }))
        XCTAssertTrue(mockLogger.debugMessages.contains(where: { $0.contains("com.test.nonconsumable") }))
        XCTAssertTrue(mockLogger.debugMessages.contains(where: { $0.contains("com.test.subscription") }))
    }

    // MARK: - Query Product Details Tests

    func testQueryProductDetailsStartsRequest() {
        sut.initialize(listener: mockListener)
        sut.queryProductDetails(productIds: ["com.test.product1", "com.test.product2"], productType: .inapp)

        XCTAssertEqual(capturedRequests.count, 1)
        XCTAssertTrue(capturedRequests.first?.startCalled == true)
    }

    func testQueryProductDetailsHandlesFailure() {
        sut.initialize(listener: mockListener)
        sut.queryProductDetails(productIds: ["com.test.product1"], productType: .inapp)

        let request = capturedRequests.first!
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        sut.request(request, didFailWithError: error)

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.storeKitErrors.count, 1)
        XCTAssertEqual(mockListener.storeKitErrors.first?.0, .error)
    }

    // MARK: - Purchase Tests

    func testPurchaseUncachedProductQueriesFirst() {
        sut.initialize(listener: mockListener)
        sut.purchase(productId: "com.test.product")

        XCTAssertEqual(capturedRequests.count, 1)
        XCTAssertTrue(capturedRequests.first?.startCalled == true)
        XCTAssertTrue(mockLogger.debugMessages.contains(where: { $0.contains("Querying product before purchase") }))
    }

    func testPurchaseProductNotFoundErrors() {
        sut.initialize(listener: mockListener)
        sut.purchase(productId: "com.test.missing")

        // Simulate response with empty products
        let request = capturedRequests.first!
        let response = MockSKProductsResponse(products: [], invalidProductIdentifiers: ["com.test.missing"])
        sut.productsRequest(request, didReceive: response)

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.storeKitErrors.count, 1)
        XCTAssertEqual(mockListener.storeKitErrors.first?.0, .itemUnavailable)
    }

    // MARK: - Transaction Observer Tests

    func testPurchasedTransactionCallsOnPurchaseCompleted() {
        sut.initialize(listener: mockListener)
        let transaction = makePurchasedTransaction(productId: "com.test.product", txId: "tx_123")

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.purchaseCompletedResults.count, 1)
        XCTAssertTrue(mockListener.purchaseCompletedResults.first?.success == true)
        XCTAssertEqual(mockListener.purchaseCompletedResults.first?.productId, "com.test.product")
        XCTAssertEqual(mockListener.purchaseCompletedResults.first?.purchaseToken, "tx_123")
    }

    func testPurchasedTransactionFinishesWhenNoServerVerify() {
        sut.initialize(listener: mockListener)
        let transaction = makePurchasedTransaction(productId: "com.test.product", txId: "tx_123")

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        XCTAssertEqual(mockQueue.finishedTransactions.count, 1)
    }

    func testPurchasedTransactionWithServerVerifyDoesNotFinish() {
        let serverVerifySut = makeServerVerifyService()
        serverVerifySut.initialize(listener: mockListener)

        let transaction = makePurchasedTransaction(productId: "com.test.product", txId: "tx_456")
        serverVerifySut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        // Should NOT finish the transaction when server verification is required
        XCTAssertEqual(mockQueue.finishedTransactions.count, 0)
        // Should call onServerVerificationRequired
        XCTAssertEqual(mockListener.serverVerificationRequiredResults.count, 1)
        // Should also call onPurchaseCompleted
        XCTAssertEqual(mockListener.purchaseCompletedResults.count, 1)
    }

    func testServerVerifyUsesRegisteredConsumableType() {
        let serverVerifySut = makeServerVerifyService()
        serverVerifySut.initialize(listener: mockListener)
        serverVerifySut.registerProduct(productId: "com.test.product", consumableType: .consumable)

        let transaction = makePurchasedTransaction(productId: "com.test.product", txId: "tx_789")
        serverVerifySut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.serverVerificationRequiredResults.first?.1, .consumable)
    }

    func testFailedTransactionCallsOnPurchaseCompletedWithError() {
        sut.initialize(listener: mockListener)
        let skError = SKError(.paymentCancelled)
        let transaction = makeFailedTransaction(productId: "com.test.product", error: skError)

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.purchaseCompletedResults.count, 1)
        XCTAssertFalse(mockListener.purchaseCompletedResults.first?.success ?? true)
        XCTAssertEqual(mockListener.purchaseCompletedResults.first?.errorCode, .userCanceled)
    }

    func testFailedTransactionAlwaysFinished() {
        sut.initialize(listener: mockListener)
        let error = NSError(domain: "test", code: 1, userInfo: nil)
        let transaction = makeFailedTransaction(productId: "com.test.product", error: error)

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        XCTAssertEqual(mockQueue.finishedTransactions.count, 1)
    }

    func testRestoredTransactionCallsOnPurchaseUpdated() {
        sut.initialize(listener: mockListener)
        let transaction = makeRestoredTransaction(productId: "com.test.product", txId: "tx_restored", originalTxId: "tx_original")

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.purchaseUpdatedResults.count, 1)
        XCTAssertTrue(mockListener.purchaseUpdatedResults.first?.success == true)
        XCTAssertEqual(mockListener.purchaseUpdatedResults.first?.orderId, "tx_original")
        XCTAssertEqual(mockListener.purchaseUpdatedResults.first?.purchaseToken, "tx_restored")
    }

    func testDeferredTransactionCallsOnPurchaseCompletedWithPending() {
        sut.initialize(listener: mockListener)
        let transaction = makeDeferredTransaction(productId: "com.test.product")

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.purchaseCompletedResults.count, 1)
        XCTAssertFalse(mockListener.purchaseCompletedResults.first?.success ?? true)
        XCTAssertEqual(mockListener.purchaseCompletedResults.first?.purchaseState, .pending)
    }

    // MARK: - Restore Purchases Tests

    func testRestorePurchasesCallsQueue() {
        sut.initialize(listener: mockListener)
        sut.restorePurchases()

        XCTAssertTrue(mockQueue.restoreCompletedTransactionsCalled)
    }

    func testRestorePurchasesCompletionCallback() {
        sut.initialize(listener: mockListener)
        sut.restorePurchases()

        // Simulate restored transactions
        let tx1 = makeRestoredTransaction(productId: "com.test.product1", txId: "tx_r1", originalTxId: "tx_o1")
        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [tx1])

        // Simulate restore finished
        sut.paymentQueueRestoreCompletedTransactionsFinished(SKPaymentQueue.default())

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.restorePurchasesCompletedResults.count, 1)
        XCTAssertEqual(mockListener.restorePurchasesCompletedResults.first?.count, 1)
    }

    func testRestorePurchasesFailureCallback() {
        sut.initialize(listener: mockListener)
        sut.restorePurchases()

        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Restore failed"])
        sut.paymentQueue(SKPaymentQueue.default(), restoreCompletedTransactionsFailedWithError: error)

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.storeKitErrors.count, 1)
    }

    // MARK: - Query Purchases Tests

    func testQueryPurchasesReturnsTrackedTransactions() {
        sut.initialize(listener: mockListener)

        // Simulate a purchased transaction that stays pending (server verify mode)
        let serverVerifySut = makeServerVerifyService()
        serverVerifySut.initialize(listener: mockListener)
        let transaction = makePurchasedTransaction(productId: "com.test.product", txId: "tx_query")
        serverVerifySut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        serverVerifySut.queryPurchases(productType: .inapp)

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.queryPurchasesCompletedResults.count, 1)
        XCTAssertEqual(mockListener.queryPurchasesCompletedResults.first?.count, 1)
    }

    func testQueryPurchasesEmptyWhenNoTransactions() {
        sut.initialize(listener: mockListener)
        sut.queryPurchases(productType: .inapp)

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.queryPurchasesCompletedResults.count, 1)
        XCTAssertEqual(mockListener.queryPurchasesCompletedResults.first?.count, 0)
    }

    // MARK: - Product Purchase Status Tests

    func testGetProductPurchaseStatusNotFound() {
        sut.initialize(listener: mockListener)
        sut.getProductPurchaseStatus(productId: "com.test.nonexistent")

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.productPurchaseStatusResults.count, 1)
        XCTAssertFalse(mockListener.productPurchaseStatusResults.first?.isPurchased ?? true)
    }

    func testGetProductPurchaseStatusFound() {
        let serverVerifySut = makeServerVerifyService()
        serverVerifySut.initialize(listener: mockListener)

        let transaction = makePurchasedTransaction(productId: "com.test.product", txId: "tx_status")
        serverVerifySut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])
        serverVerifySut.getProductPurchaseStatus(productId: "com.test.product")

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.productPurchaseStatusResults.count, 1)
        XCTAssertTrue(mockListener.productPurchaseStatusResults.first?.isPurchased ?? false)
        XCTAssertEqual(mockListener.productPurchaseStatusResults.first?.purchaseToken, "tx_status")
    }

    // MARK: - Complete Purchase Processing Tests

    func testCompletePurchaseProcessingFinishesTransaction() {
        let serverVerifySut = makeServerVerifyService()
        serverVerifySut.initialize(listener: mockListener)

        let transaction = makePurchasedTransaction(productId: "com.test.product", txId: "tx_complete")
        serverVerifySut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        let exp = expectation(description: "callback")
        serverVerifySut.completePurchaseProcessing(
            purchaseToken: "tx_complete",
            consumableType: .consumable,
            verified: true
        ) { success in
            XCTAssertTrue(success)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(mockQueue.finishedTransactions.count, 1)
    }

    func testCompletePurchaseProcessingFailsWhenNotVerified() {
        let serverVerifySut = makeServerVerifyService()
        serverVerifySut.initialize(listener: mockListener)

        let transaction = makePurchasedTransaction(productId: "com.test.product", txId: "tx_fail")
        serverVerifySut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        let exp = expectation(description: "callback")
        serverVerifySut.completePurchaseProcessing(
            purchaseToken: "tx_fail",
            consumableType: .consumable,
            verified: false
        ) { success in
            XCTAssertFalse(success)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        // Should NOT finish the transaction when verification failed
        XCTAssertEqual(mockQueue.finishedTransactions.count, 0)
    }

    func testCompletePurchaseProcessingNotFoundReturnsTrue() {
        sut.initialize(listener: mockListener)

        let exp = expectation(description: "callback")
        sut.completePurchaseProcessing(
            purchaseToken: "tx_nonexistent",
            consumableType: .consumable,
            verified: true
        ) { success in
            XCTAssertTrue(success, "Should return true for already-finished transaction")
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Error Mapping Tests

    func testSKErrorPaymentCancelledMapsToUserCanceled() {
        sut.initialize(listener: mockListener)
        let skError = SKError(.paymentCancelled)
        let transaction = makeFailedTransaction(productId: "com.test.product", error: skError)

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.purchaseCompletedResults.first?.errorCode, .userCanceled)
    }

    func testSKErrorNetworkMapsToNetworkError() {
        sut.initialize(listener: mockListener)
        let skError = SKError(.cloudServiceNetworkConnectionFailed)
        let transaction = makeFailedTransaction(productId: "com.test.product", error: skError)

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.purchaseCompletedResults.first?.errorCode, .networkError)
    }

    func testSKErrorProductNotAvailableMapsToItemUnavailable() {
        sut.initialize(listener: mockListener)
        let skError = SKError(.storeProductNotAvailable)
        let transaction = makeFailedTransaction(productId: "com.test.product", error: skError)

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.purchaseCompletedResults.first?.errorCode, .itemUnavailable)
    }

    func testSKErrorPaymentInvalidMapsToDeveloperError() {
        sut.initialize(listener: mockListener)
        let skError = SKError(.paymentInvalid)
        let transaction = makeFailedTransaction(productId: "com.test.product", error: skError)

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.purchaseCompletedResults.first?.errorCode, .developerError)
    }

    func testSKErrorPermissionDeniedMapsToServiceUnavailable() {
        sut.initialize(listener: mockListener)
        let skError = SKError(.cloudServicePermissionDenied)
        let transaction = makeFailedTransaction(productId: "com.test.product", error: skError)

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.purchaseCompletedResults.first?.errorCode, .serviceUnavailable)
    }

    func testGenericErrorMapsToError() {
        sut.initialize(listener: mockListener)
        let genericError = NSError(domain: "test", code: 999, userInfo: [NSLocalizedDescriptionKey: "Generic"])
        let transaction = makeFailedTransaction(productId: "com.test.product", error: genericError)

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.purchaseCompletedResults.first?.errorCode, .error)
    }

    // MARK: - Receipt Tests

    func testPurchaseResultHasEmptyTransactionJson() {
        sut.initialize(listener: mockListener)
        let transaction = makePurchasedTransaction(productId: "com.test.product", txId: "tx_receipt")

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        // SK1 has no per-transaction JWS
        XCTAssertEqual(mockListener.purchaseCompletedResults.first?.transactionJson, "")
    }

    func testPurchaseResultPurchaseStateIsPurchased() {
        sut.initialize(listener: mockListener)
        let transaction = makePurchasedTransaction(productId: "com.test.product", txId: "tx_state")

        sut.paymentQueue(SKPaymentQueue.default(), updatedTransactions: [transaction])

        // Wait for async dispatch
        let exp = expectation(description: "async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(mockListener.purchaseCompletedResults.first?.purchaseState, .purchased)
    }

    // MARK: - Conformance Tests

    func testServiceIsNSObject() {
        XCTAssertNotNil(sut as NSObject?)
    }

    func testServiceConformsToStoreKitServiceProtocol() {
        XCTAssertNotNil(sut as (any StoreKitServiceProtocol)?)
    }

    func testServiceConformsToSKPaymentTransactionObserver() {
        XCTAssertNotNil(sut as (any SKPaymentTransactionObserver)?)
    }

    func testServiceConformsToSKProductsRequestDelegate() {
        XCTAssertNotNil(sut as (any SKProductsRequestDelegate)?)
    }
}

// MARK: - Mock SKProductsResponse

class MockSKProductsResponse: SKProductsResponse, @unchecked Sendable {
    private let _products: [SKProduct]
    private let _invalidProductIdentifiers: [String]

    init(products: [SKProduct], invalidProductIdentifiers: [String] = []) {
        self._products = products
        self._invalidProductIdentifiers = invalidProductIdentifiers
        super.init()
    }

    override var products: [SKProduct] { _products }
    override var invalidProductIdentifiers: [String] { _invalidProductIdentifiers }
}
