import Foundation
import StoreKit

/// StoreKit 1 fallback for iOS 14 devices.
/// Provides basic purchase functionality with the same StoreKitServiceProtocol interface.
/// Limitations: no subscription offer details, receipt-based verification, limited query accuracy.
class StoreKitLegacyService: NSObject, StoreKitServiceProtocol, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    private let logger: NoctuaLogger
    private let config: NoctuaStoreKitConfig
    private weak var eventListener: StoreKitEventListener?
    private var productTypeMap: [String: ConsumableType] = [:]
    private var cachedSKProducts: [String: SKProduct] = [:]
    private var isInitialized = false

    // Pending operation tracking
    private var pendingPurchaseProductId: String?
    private var pendingQueryProductIds: [String]?
    private var pendingQueryProductType: ProductType?

    init(config: NoctuaStoreKitConfig, logger: NoctuaLogger = IOSLogger(category: "StoreKitLegacyService")) {
        self.config = config
        self.logger = logger
        super.init()
    }

    // MARK: - StoreKitServiceProtocol

    func initialize(listener: StoreKitEventListener?) {
        guard !isInitialized else {
            logger.warning("StoreKitLegacyService already initialized")
            return
        }

        self.eventListener = listener
        SKPaymentQueue.default().add(self)
        isInitialized = true
        logger.info("StoreKitLegacyService initialized (StoreKit 1 fallback)")
    }

    func dispose() {
        SKPaymentQueue.default().remove(self)
        isInitialized = false
        logger.info("StoreKitLegacyService disposed")
    }

    func isReady() -> Bool {
        return isInitialized && SKPaymentQueue.canMakePayments()
    }

    func registerProduct(productId: String, consumableType: ConsumableType) {
        productTypeMap[productId] = consumableType
        logger.debug("Registered product: \(productId) as \(consumableType)")
    }

    func queryProductDetails(productIds: [String], productType: ProductType) {
        pendingQueryProductIds = productIds
        pendingQueryProductType = productType
        pendingPurchaseProductId = nil

        let request = SKProductsRequest(productIdentifiers: Set(productIds))
        request.delegate = self
        request.start()
    }

    func purchase(productId: String) {
        guard isReady() else {
            eventListener?.onStoreKitError(error: .serviceDisconnected, message: "StoreKit not ready")
            return
        }

        // Check if product is cached
        if let product = cachedSKProducts[productId] {
            let payment = SKPayment(product: product)
            pendingPurchaseProductId = productId
            pendingQueryProductIds = nil
            SKPaymentQueue.default().add(payment)
        } else {
            // Need to fetch product first
            pendingPurchaseProductId = productId
            pendingQueryProductIds = nil
            let request = SKProductsRequest(productIdentifiers: [productId])
            request.delegate = self
            request.start()
        }
    }

    func queryPurchases(productType: ProductType) {
        // StoreKit 1 has limited purchase query capability.
        // We check receipt data for purchased products.
        var results: [NoctuaPurchaseResult] = []

        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: appStoreReceiptURL.path),
           let receiptData = try? Data(contentsOf: appStoreReceiptURL) {
            let receiptString = receiptData.base64EncodedString()

            // For registered products, create a basic purchase result
            for (productId, consumableType) in productTypeMap {
                let matchesType: Bool
                switch productType {
                case .inapp:
                    matchesType = consumableType == .consumable || consumableType == .nonConsumable
                case .subs:
                    matchesType = consumableType == .subscription
                }

                if matchesType {
                    // We can't definitively verify individual products from receipt in SK1 without server
                    // Just report that receipt exists
                    results.append(NoctuaPurchaseResult(
                        success: true,
                        purchaseState: .purchased,
                        productId: productId,
                        originalJson: receiptString
                    ))
                }
            }
        }

        logger.debug("Queried \(results.count) purchases (legacy, receipt-based)")
        eventListener?.onQueryPurchasesCompleted(purchases: results)
    }

    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    func getProductPurchaseStatus(productId: String) {
        // StoreKit 1: Limited — check receipt for any purchase data
        var isPurchased = false
        var receiptString = ""

        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: appStoreReceiptURL.path),
           let receiptData = try? Data(contentsOf: appStoreReceiptURL) {
            receiptString = receiptData.base64EncodedString()
            // Without server-side receipt validation, we can't definitively check
            // For now, we check if any transactions exist in the queue
            isPurchased = false // Conservative — caller should use server verification
        }

        let status = NoctuaProductPurchaseStatus(
            productId: productId,
            isPurchased: isPurchased,
            originalJson: receiptString
        )

        logger.debug("Product purchase status for \(productId): isPurchased=\(status.isPurchased) (legacy)")
        eventListener?.onProductPurchaseStatusResult(status: status)
    }

    func completePurchaseProcessing(purchaseToken: String, consumableType: ConsumableType, verified: Bool, callback: ((Bool) -> Void)?) {
        guard verified else {
            logger.warning("Server verification failed for token: \(purchaseToken.prefix(20))...")
            callback?(false)
            return
        }

        // In StoreKit 1, transactions are finished in paymentQueue(_:updatedTransactions:)
        // If server verification is enabled, we deferred finishing — now finish pending transactions
        for transaction in SKPaymentQueue.default().transactions {
            if transaction.transactionIdentifier == purchaseToken {
                SKPaymentQueue.default().finishTransaction(transaction)
                logger.debug("Purchase processing completed for token: \(purchaseToken.prefix(20))...")
                callback?(true)
                return
            }
        }

        logger.debug("Transaction already finished or not found: \(purchaseToken.prefix(20))...")
        callback?(true)
    }

    // MARK: - SKProductsRequestDelegate

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // Cache all products
        for product in response.products {
            cachedSKProducts[product.productIdentifier] = product
        }

        // Check if this was a purchase request
        if let purchaseProductId = pendingPurchaseProductId {
            if let product = response.products.first(where: { $0.productIdentifier == purchaseProductId }) {
                let payment = SKPayment(product: product)
                SKPaymentQueue.default().add(payment)
            } else {
                logger.error("Product not found for purchase: \(purchaseProductId)")
                eventListener?.onStoreKitError(
                    error: .itemUnavailable,
                    message: "Product not found: \(purchaseProductId)"
                )
            }
            pendingPurchaseProductId = nil
            return
        }

        // This was a queryProductDetails request
        if let queryProductType = pendingQueryProductType {
            let filtered = response.products.filter { product in
                let consumableType = productTypeMap[product.productIdentifier]
                switch queryProductType {
                case .inapp:
                    return consumableType == .consumable || consumableType == .nonConsumable || consumableType == nil
                case .subs:
                    return consumableType == .subscription
                }
            }

            let results = filtered.map { mapSKProduct($0) }
            logger.debug("Loaded \(results.count) product details (legacy)")
            eventListener?.onProductDetailsLoaded(products: results)

            pendingQueryProductIds = nil
            pendingQueryProductType = nil
        }

        // Report invalid product identifiers
        for invalidId in response.invalidProductIdentifiers {
            logger.warning("Invalid product identifier: \(invalidId)")
        }
    }

    // MARK: - SKPaymentTransactionObserver

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let productId = transaction.payment.productIdentifier

            switch transaction.transactionState {
            case .purchased:
                handlePurchasedTransaction(transaction, productId: productId)

            case .restored:
                handleRestoredTransaction(transaction, productId: productId)

            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                let errorCode = mapSKError(transaction.error)
                let message = transaction.error?.localizedDescription ?? "Payment failed"
                logger.warning("Payment failed for \(productId): \(message)")

                let result = NoctuaPurchaseResult(
                    success: false,
                    errorCode: errorCode,
                    productId: productId,
                    message: message
                )
                eventListener?.onPurchaseCompleted(result: result)

            case .deferred:
                logger.info("Payment deferred for \(productId)")
                let result = NoctuaPurchaseResult(
                    success: false,
                    purchaseState: .pending,
                    productId: productId,
                    message: "Payment deferred"
                )
                eventListener?.onPurchaseCompleted(result: result)

            case .purchasing:
                logger.debug("Transaction in progress for \(productId)")

            @unknown default:
                logger.warning("Unknown transaction state for \(productId)")
            }
        }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        var restoredPurchases: [NoctuaPurchaseResult] = []

        for transaction in queue.transactions {
            if transaction.transactionState == .restored {
                restoredPurchases.append(mapSKTransaction(transaction))
            }
        }

        logger.debug("Restore completed: \(restoredPurchases.count) purchases restored")
        eventListener?.onRestorePurchasesCompleted(purchases: restoredPurchases)
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        logger.error("Restore failed: \(error.localizedDescription)")
        eventListener?.onStoreKitError(error: .error, message: "Restore failed: \(error.localizedDescription)")
    }

    // MARK: - Private Helpers

    private func handlePurchasedTransaction(_ transaction: SKPaymentTransaction, productId: String) {
        let consumableType = productTypeMap[productId] ?? .nonConsumable

        if config.verifyPurchasesOnServer {
            // Don't finish transaction — defer to server verification
            let result = mapSKTransaction(transaction)
            logger.debug("Server verification required for \(productId)")
            eventListener?.onServerVerificationRequired(result: result, consumableType: consumableType)
            eventListener?.onPurchaseCompleted(result: result)
        } else {
            SKPaymentQueue.default().finishTransaction(transaction)
            let result = mapSKTransaction(transaction)
            eventListener?.onPurchaseCompleted(result: result)
        }
    }

    private func handleRestoredTransaction(_ transaction: SKPaymentTransaction, productId: String) {
        let consumableType = productTypeMap[productId] ?? .nonConsumable

        if config.verifyPurchasesOnServer {
            let result = mapSKTransaction(transaction)
            eventListener?.onServerVerificationRequired(result: result, consumableType: consumableType)
        } else {
            SKPaymentQueue.default().finishTransaction(transaction)
        }

        let result = mapSKTransaction(transaction)
        eventListener?.onPurchaseUpdated(result: result)
    }

    private func mapSKProduct(_ product: SKProduct) -> NoctuaProductDetails {
        let priceMicros = product.price.multiplying(by: NSDecimalNumber(value: 1_000_000)).int64Value

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let formattedPrice = formatter.string(from: product.price) ?? "\(product.price)"

        let consumableType = productTypeMap[product.productIdentifier]
        let productType: ProductType = (consumableType == .subscription) ? .subs : .inapp

        return NoctuaProductDetails(
            productId: product.productIdentifier,
            title: product.localizedTitle,
            productDescription: product.localizedDescription,
            formattedPrice: formattedPrice,
            priceAmountMicros: priceMicros,
            priceCurrencyCode: product.priceLocale.currencyCode ?? "",
            productType: productType,
            subscriptionOfferDetails: nil // Not available in StoreKit 1
        )
    }

    private func mapSKTransaction(_ transaction: SKPaymentTransaction) -> NoctuaPurchaseResult {
        let productId = transaction.payment.productIdentifier
        let consumableType = productTypeMap[productId]
        let isAutoRenewing = consumableType == .subscription

        // Get receipt data
        var receiptString = ""
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           let receiptData = try? Data(contentsOf: appStoreReceiptURL) {
            receiptString = receiptData.base64EncodedString()
        }

        return NoctuaPurchaseResult(
            success: true,
            errorCode: .ok,
            purchaseState: .purchased,
            productId: productId,
            orderId: transaction.transactionIdentifier,
            purchaseToken: transaction.transactionIdentifier ?? "",
            purchaseTime: Int64((transaction.transactionDate?.timeIntervalSince1970 ?? 0) * 1000),
            isAcknowledged: true,
            isAutoRenewing: isAutoRenewing,
            quantity: transaction.payment.quantity,
            message: "",
            originalJson: receiptString
        )
    }

    private func mapSKError(_ error: Error?) -> StoreKitErrorCode {
        guard let skError = error as? SKError else { return .error }

        switch skError.code {
        case .paymentCancelled:
            return .userCanceled
        case .paymentNotAllowed:
            return .storeKitUnavailable
        case .storeProductNotAvailable:
            return .itemUnavailable
        case .paymentInvalid:
            return .developerError
        case .cloudServiceNetworkConnectionFailed:
            return .networkError
        default:
            return .error
        }
    }
}
