import Foundation

class StoreKitPresenter {
    private let storeKitService: StoreKitServiceProtocol?
    private let logger: NoctuaLogger

    // Callback storage (matches Android NoctuaPresenter pattern)
    // fileprivate to allow access from StoreKitEventListenerBridge in this file
    fileprivate var onPurchaseCompleted: ((NoctuaPurchaseResult) -> Void)?
    fileprivate var onPurchaseUpdated: ((NoctuaPurchaseResult) -> Void)?
    fileprivate var onProductDetailsLoaded: (([NoctuaProductDetails]) -> Void)?
    fileprivate var onQueryPurchasesCompleted: (([NoctuaPurchaseResult]) -> Void)?
    fileprivate var onRestorePurchasesCompleted: (([NoctuaPurchaseResult]) -> Void)?
    fileprivate var onProductPurchaseStatusResult: ((NoctuaProductPurchaseStatus) -> Void)?
    fileprivate var onServerVerificationRequired: ((NoctuaPurchaseResult, ConsumableType) -> Void)?
    fileprivate var onStoreKitError: ((StoreKitErrorCode, String) -> Void)?

    init(storeKitService: StoreKitServiceProtocol?, logger: NoctuaLogger) {
        self.storeKitService = storeKitService
        self.logger = logger
    }

    // MARK: - Initialization

    func initializeStoreKit(
        onPurchaseCompleted: ((NoctuaPurchaseResult) -> Void)? = nil,
        onPurchaseUpdated: ((NoctuaPurchaseResult) -> Void)? = nil,
        onProductDetailsLoaded: (([NoctuaProductDetails]) -> Void)? = nil,
        onQueryPurchasesCompleted: (([NoctuaPurchaseResult]) -> Void)? = nil,
        onRestorePurchasesCompleted: (([NoctuaPurchaseResult]) -> Void)? = nil,
        onProductPurchaseStatusResult: ((NoctuaProductPurchaseStatus) -> Void)? = nil,
        onServerVerificationRequired: ((NoctuaPurchaseResult, ConsumableType) -> Void)? = nil,
        onStoreKitError: ((StoreKitErrorCode, String) -> Void)? = nil
    ) {
        self.onPurchaseCompleted = onPurchaseCompleted
        self.onPurchaseUpdated = onPurchaseUpdated
        self.onProductDetailsLoaded = onProductDetailsLoaded
        self.onQueryPurchasesCompleted = onQueryPurchasesCompleted
        self.onRestorePurchasesCompleted = onRestorePurchasesCompleted
        self.onProductPurchaseStatusResult = onProductPurchaseStatusResult
        self.onServerVerificationRequired = onServerVerificationRequired
        self.onStoreKitError = onStoreKitError

        let listenerBridge = StoreKitEventListenerBridge(presenter: self)
        storeKitService?.initialize(listener: listenerBridge)

        // Hold a strong reference to the bridge
        self.eventListenerBridge = listenerBridge

        logger.info("StoreKitPresenter initialized")
    }

    // Strong reference to prevent deallocation
    private var eventListenerBridge: StoreKitEventListenerBridge?

    // MARK: - Product Registration & Query

    func registerProduct(productId: String, consumableType: ConsumableType) {
        storeKitService?.registerProduct(productId: productId, consumableType: consumableType)
    }

    func queryProductDetails(productIds: [String], productType: ProductType = .inapp) {
        storeKitService?.queryProductDetails(productIds: productIds, productType: productType)
    }

    // MARK: - Purchase

    func purchase(productId: String) {
        logger.debug("Purchase requested for: \(productId)")
        storeKitService?.purchase(productId: productId)
    }

    // MARK: - Query & Restore

    func queryPurchases(productType: ProductType = .inapp) {
        storeKitService?.queryPurchases(productType: productType)
    }

    func restorePurchases() {
        storeKitService?.restorePurchases()
    }

    func getProductPurchaseStatus(productId: String) {
        storeKitService?.getProductPurchaseStatus(productId: productId)
    }

    // MARK: - Server Verification

    func completePurchaseProcessing(
        purchaseToken: String,
        consumableType: ConsumableType,
        verified: Bool,
        callback: ((Bool) -> Void)? = nil
    ) {
        storeKitService?.completePurchaseProcessing(
            purchaseToken: purchaseToken,
            consumableType: consumableType,
            verified: verified,
            callback: callback
        )
    }

    // MARK: - Lifecycle

    func disposeStoreKit() {
        storeKitService?.dispose()
        eventListenerBridge = nil
    }

    func isStoreKitReady() -> Bool {
        return storeKitService?.isReady() ?? false
    }
}

// MARK: - Event Listener Bridge

/// Bridges StoreKitEventListener protocol calls to the presenter's stored callbacks.
private class StoreKitEventListenerBridge: StoreKitEventListener {
    private weak var presenter: StoreKitPresenter?

    init(presenter: StoreKitPresenter) {
        self.presenter = presenter
    }

    func onPurchaseCompleted(result: NoctuaPurchaseResult) {
        presenter?.onPurchaseCompleted?(result)
    }

    func onPurchaseUpdated(result: NoctuaPurchaseResult) {
        presenter?.onPurchaseUpdated?(result)
    }

    func onProductDetailsLoaded(products: [NoctuaProductDetails]) {
        presenter?.onProductDetailsLoaded?(products)
    }

    func onQueryPurchasesCompleted(purchases: [NoctuaPurchaseResult]) {
        presenter?.onQueryPurchasesCompleted?(purchases)
    }

    func onRestorePurchasesCompleted(purchases: [NoctuaPurchaseResult]) {
        presenter?.onRestorePurchasesCompleted?(purchases)
    }

    func onProductPurchaseStatusResult(status: NoctuaProductPurchaseStatus) {
        presenter?.onProductPurchaseStatusResult?(status)
    }

    func onServerVerificationRequired(result: NoctuaPurchaseResult, consumableType: ConsumableType) {
        presenter?.onServerVerificationRequired?(result, consumableType)
    }

    func onStoreKitError(error: StoreKitErrorCode, message: String) {
        presenter?.onStoreKitError?(error, message)
    }
}
