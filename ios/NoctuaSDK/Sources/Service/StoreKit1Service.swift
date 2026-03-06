import Foundation
import StoreKit

// MARK: - PaymentQueue Protocol for Testability

protocol PaymentQueueProtocol: AnyObject {
    func add(_ observer: SKPaymentTransactionObserver)
    func remove(_ observer: SKPaymentTransactionObserver)
    func add(_ payment: SKPayment)
    func restoreCompletedTransactions()
    func finishTransaction(_ transaction: SKPaymentTransaction)
}

extension SKPaymentQueue: PaymentQueueProtocol {}

// MARK: - Product Request Factory

typealias ProductRequestFactory = (Set<String>) -> SKProductsRequest

// MARK: - StoreKit1Service

class StoreKit1Service: NSObject, StoreKitServiceProtocol, SKPaymentTransactionObserver, SKProductsRequestDelegate {
    private let logger: NoctuaLogger
    private let config: NoctuaStoreKitConfig
    private let paymentQueue: PaymentQueueProtocol
    private let productRequestFactory: ProductRequestFactory

    private weak var eventListener: StoreKitEventListener?
    private var productTypeMap: [String: ConsumableType] = [:]
    private var cachedProducts: [String: SKProduct] = [:]
    private var isInitialized = false

    // Track unfinished transactions for completePurchaseProcessing
    private var pendingTransactions: [String: SKPaymentTransaction] = [:]

    // Track active product requests to prevent deallocation
    private var activeRequests: [SKProductsRequest] = []

    // Track which product type was requested for filtering
    private var pendingQueryProductType: ProductType = .inapp

    // Track auto-purchase after product query
    private var pendingPurchaseProductId: String?

    // Track restored transactions for batch callback
    private var pendingRestoreResults: [NoctuaPurchaseResult] = []

    init(
        config: NoctuaStoreKitConfig,
        logger: NoctuaLogger = IOSLogger(category: "StoreKit1Service"),
        paymentQueue: PaymentQueueProtocol = SKPaymentQueue.default(),
        productRequestFactory: @escaping ProductRequestFactory = { SKProductsRequest(productIdentifiers: $0) }
    ) {
        self.config = config
        self.logger = logger
        self.paymentQueue = paymentQueue
        self.productRequestFactory = productRequestFactory
        super.init()
    }

    // MARK: - StoreKitServiceProtocol

    func initialize(listener: StoreKitEventListener?) {
        guard !isInitialized else {
            logger.warning("StoreKit1Service already initialized")
            return
        }

        self.eventListener = listener
        paymentQueue.add(self)
        isInitialized = true

        logger.info("StoreKit1Service initialized (StoreKit 1)")
    }

    func dispose() {
        paymentQueue.remove(self)
        pendingTransactions.removeAll()
        activeRequests.removeAll()
        pendingPurchaseProductId = nil
        pendingRestoreResults.removeAll()
        isInitialized = false
        logger.info("StoreKit1Service disposed")
    }

    func isReady() -> Bool {
        return isInitialized
    }

    func registerProduct(productId: String, consumableType: ConsumableType) {
        productTypeMap[productId] = consumableType
        logger.debug("Registered product: \(productId) as \(consumableType)")
    }

    func queryProductDetails(productIds: [String], productType: ProductType) {
        pendingQueryProductType = productType
        let request = productRequestFactory(Set(productIds))
        request.delegate = self
        activeRequests.append(request)
        request.start()
        logger.debug("Started product details query for \(productIds.count) products (SK1)")
    }

    func purchase(productId: String) {
        if let product = cachedProducts[productId] {
            let payment = SKPayment(product: product)
            paymentQueue.add(payment)
            logger.debug("Added payment to queue for \(productId) (SK1)")
        } else {
            // Query product first, then purchase in the callback
            pendingPurchaseProductId = productId
            let request = productRequestFactory([productId])
            request.delegate = self
            activeRequests.append(request)
            request.start()
            logger.debug("Querying product before purchase: \(productId) (SK1)")
        }
    }

    func queryPurchases(productType: ProductType) {
        // SK1 has no Transaction.currentEntitlements equivalent.
        // Report currently tracked pending (unfinished) transactions.
        var purchases: [NoctuaPurchaseResult] = []

        for (_, transaction) in pendingTransactions {
            if transaction.transactionState == .purchased || transaction.transactionState == .restored {
                let matchesType = doesTransactionMatchType(transaction, productType: productType)
                if matchesType {
                    purchases.append(mapSKPaymentTransaction(transaction))
                }
            }
        }

        let finalResults = purchases
        logger.debug("Queried \(finalResults.count) purchases for type \(productType) (SK1)")
        DispatchQueue.main.async { [weak self] in
            self?.eventListener?.onQueryPurchasesCompleted(purchases: finalResults)
        }
    }

    func restorePurchases() {
        pendingRestoreResults.removeAll()
        paymentQueue.restoreCompletedTransactions()
        logger.debug("Restore purchases initiated (SK1)")
    }

    func getProductPurchaseStatus(productId: String) {
        // Check pending transactions for this product
        let matchingTransaction = pendingTransactions.values.first {
            $0.payment.productIdentifier == productId &&
            ($0.transactionState == .purchased || $0.transactionState == .restored)
        }

        let status: NoctuaProductPurchaseStatus
        if let transaction = matchingTransaction {
            let product = cachedProducts[productId]
            let isSubscription = product?.subscriptionPeriod != nil
            status = NoctuaProductPurchaseStatus(
                productId: productId,
                isPurchased: true,
                isAcknowledged: true,
                isAutoRenewing: isSubscription,
                purchaseState: .purchased,
                purchaseToken: transaction.transactionIdentifier ?? "",
                purchaseTime: Int64((transaction.transactionDate?.timeIntervalSince1970 ?? 0) * 1000),
                expiryTime: 0, // SK1 doesn't expose expiry directly
                orderId: transaction.original?.transactionIdentifier ?? transaction.transactionIdentifier ?? "",
                originalJson: getAppStoreReceipt(),
                transactionJson: "" // SK1 has no per-transaction JWS
            )
        } else {
            status = NoctuaProductPurchaseStatus(
                productId: productId,
                isPurchased: false
            )
        }

        logger.debug("Product purchase status for \(productId): isPurchased=\(status.isPurchased) (SK1)")
        DispatchQueue.main.async { [weak self] in
            self?.eventListener?.onProductPurchaseStatusResult(status: status)
        }
    }

    func completePurchaseProcessing(purchaseToken: String, consumableType: ConsumableType, verified: Bool, callback: ((Bool) -> Void)?) {
        guard verified else {
            logger.warning("Server verification failed for token: \(purchaseToken.prefix(20))...")
            callback?(false)
            return
        }

        if let transaction = pendingTransactions[purchaseToken] {
            paymentQueue.finishTransaction(transaction)
            pendingTransactions.removeValue(forKey: purchaseToken)
            logger.debug("Purchase processing completed for token: \(purchaseToken.prefix(20))... (SK1)")
            DispatchQueue.main.async { callback?(true) }
        } else {
            // Transaction may have already been finished
            logger.debug("Transaction already finished or not found: \(purchaseToken.prefix(20))... (SK1)")
            DispatchQueue.main.async { callback?(true) }
        }
    }

    // MARK: - SKPaymentTransactionObserver

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handlePurchasedTransaction(transaction)
            case .failed:
                handleFailedTransaction(transaction)
            case .restored:
                handleRestoredTransaction(transaction)
            case .deferred:
                handleDeferredTransaction(transaction)
            case .purchasing:
                logger.debug("Transaction purchasing: \(transaction.payment.productIdentifier)")
            @unknown default:
                logger.warning("Unknown transaction state for \(transaction.payment.productIdentifier)")
            }
        }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        let restoredPurchases = pendingRestoreResults
        pendingRestoreResults.removeAll()

        logger.debug("Restore purchases completed: \(restoredPurchases.count) purchases found (SK1)")
        DispatchQueue.main.async { [weak self] in
            self?.eventListener?.onRestorePurchasesCompleted(purchases: restoredPurchases)
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        pendingRestoreResults.removeAll()

        logger.error("Failed to restore purchases: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.eventListener?.onStoreKitError(
                error: .error,
                message: "Failed to restore purchases: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - SKProductsRequestDelegate

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // Check if this is a purchase-triggered query
        if let purchaseProductId = pendingPurchaseProductId {
            pendingPurchaseProductId = nil

            if let product = response.products.first(where: { $0.productIdentifier == purchaseProductId }) {
                cachedProducts[product.productIdentifier] = product
                let payment = SKPayment(product: product)
                paymentQueue.add(payment)
                logger.debug("Auto-purchased after query: \(purchaseProductId) (SK1)")
            } else {
                logger.error("Product not found for purchase: \(purchaseProductId)")
                DispatchQueue.main.async { [weak self] in
                    self?.eventListener?.onStoreKitError(
                        error: .itemUnavailable,
                        message: "Product not found: \(purchaseProductId)"
                    )
                }
            }

            cleanupRequest(request)
            return
        }

        // Standard product details query
        let filtered = response.products.filter { product in
            let isSubscription = product.subscriptionPeriod != nil
            switch pendingQueryProductType {
            case .inapp: return !isSubscription
            case .subs: return isSubscription
            }
        }

        for product in filtered {
            cachedProducts[product.productIdentifier] = product
        }

        let results = filtered.map { mapSKProduct($0) }
        logger.debug("Loaded \(results.count) product details (SK1)")

        DispatchQueue.main.async { [weak self] in
            self?.eventListener?.onProductDetailsLoaded(products: results)
        }

        cleanupRequest(request)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        logger.error("SKProductsRequest failed: \(error.localizedDescription)")

        // If this was a purchase-triggered query, clear the pending purchase
        if pendingPurchaseProductId != nil {
            let productId = pendingPurchaseProductId!
            pendingPurchaseProductId = nil
            DispatchQueue.main.async { [weak self] in
                self?.eventListener?.onStoreKitError(
                    error: .error,
                    message: "Failed to fetch product for purchase: \(productId): \(error.localizedDescription)"
                )
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.eventListener?.onStoreKitError(
                    error: .error,
                    message: "Failed to query product details: \(error.localizedDescription)"
                )
            }
        }

        if let productsRequest = request as? SKProductsRequest {
            cleanupRequest(productsRequest)
        }
    }

    // MARK: - Private Transaction Handlers

    private func handlePurchasedTransaction(_ transaction: SKPaymentTransaction) {
        let productId = transaction.payment.productIdentifier
        let purchaseResult = mapSKPaymentTransaction(transaction)

        // Store for completePurchaseProcessing
        if let txId = transaction.transactionIdentifier {
            pendingTransactions[txId] = transaction
        }

        let consumableType = productTypeMap[productId] ?? .nonConsumable

        if config.verifyPurchasesOnServer {
            logger.debug("Server verification required for \(productId) (type: \(consumableType)) (SK1)")
            DispatchQueue.main.async { [weak self] in
                self?.eventListener?.onServerVerificationRequired(
                    result: purchaseResult,
                    consumableType: consumableType
                )
            }
        } else {
            paymentQueue.finishTransaction(transaction)
            if let txId = transaction.transactionIdentifier {
                pendingTransactions.removeValue(forKey: txId)
            }
            logger.debug("Transaction finished for \(productId) (SK1)")
        }

        DispatchQueue.main.async { [weak self] in
            self?.eventListener?.onPurchaseCompleted(result: purchaseResult)
        }
    }

    private func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        let productId = transaction.payment.productIdentifier
        let error = transaction.error as? SKError

        let errorCode: StoreKitErrorCode
        let message: String

        if let skError = error {
            errorCode = mapSKError(skError)
            message = skError.localizedDescription
        } else {
            errorCode = .error
            message = transaction.error?.localizedDescription ?? "Unknown error"
        }

        // Always finish failed transactions
        paymentQueue.finishTransaction(transaction)

        let purchaseResult = NoctuaPurchaseResult(
            success: false,
            errorCode: errorCode,
            productId: productId,
            message: message
        )

        logger.error("Transaction failed for \(productId): \(message) (SK1)")
        DispatchQueue.main.async { [weak self] in
            self?.eventListener?.onPurchaseCompleted(result: purchaseResult)
        }
    }

    private func handleRestoredTransaction(_ transaction: SKPaymentTransaction) {
        let productId = transaction.payment.productIdentifier

        if let txId = transaction.transactionIdentifier {
            pendingTransactions[txId] = transaction
        }

        let consumableType = productTypeMap[productId] ?? .nonConsumable
        let purchaseResult = mapSKPaymentTransaction(transaction)

        // Collect for restore batch callback
        pendingRestoreResults.append(purchaseResult)

        if config.verifyPurchasesOnServer {
            DispatchQueue.main.async { [weak self] in
                self?.eventListener?.onServerVerificationRequired(
                    result: purchaseResult,
                    consumableType: consumableType
                )
            }
        } else {
            paymentQueue.finishTransaction(transaction)
            if let txId = transaction.transactionIdentifier {
                pendingTransactions.removeValue(forKey: txId)
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.eventListener?.onPurchaseUpdated(result: purchaseResult)
        }
    }

    private func handleDeferredTransaction(_ transaction: SKPaymentTransaction) {
        let productId = transaction.payment.productIdentifier
        logger.info("Purchase deferred for \(productId) (SK1)")

        let purchaseResult = NoctuaPurchaseResult(
            success: false,
            purchaseState: .pending,
            productId: productId,
            message: "Purchase is pending approval (Ask to Buy)"
        )

        DispatchQueue.main.async { [weak self] in
            self?.eventListener?.onPurchaseCompleted(result: purchaseResult)
        }
    }

    // MARK: - Receipt Helper

    private func getAppStoreReceipt() -> String {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            logger.warning("Failed to read receipt from appStoreReceiptURL")
            return ""
        }
        return receiptData.base64EncodedString()
    }

    // MARK: - Mapping Helpers

    private func mapSKProduct(_ product: SKProduct) -> NoctuaProductDetails {
        let isSubscription = product.subscriptionPeriod != nil
        let productType: ProductType = isSubscription ? .subs : .inapp
        let priceMicros = product.price.multiplying(by: NSDecimalNumber(value: 1_000_000)).int64Value
        let currencyCode = product.priceLocale.currencyCode ?? "USD"

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let formattedPrice = formatter.string(from: product.price) ?? "\(product.price)"

        return NoctuaProductDetails(
            productId: product.productIdentifier,
            title: product.localizedTitle,
            productDescription: product.localizedDescription,
            formattedPrice: formattedPrice,
            priceAmountMicros: priceMicros,
            priceCurrencyCode: currencyCode,
            productType: productType,
            subscriptionOfferDetails: isSubscription ? mapSK1SubscriptionOffers(product) : nil
        )
    }

    private func mapSK1SubscriptionOffers(_ product: SKProduct) -> [NoctuaSubscriptionOfferDetails]? {
        guard let period = product.subscriptionPeriod else { return nil }

        let priceMicros = product.price.multiplying(by: NSDecimalNumber(value: 1_000_000)).int64Value
        let currencyCode = product.priceLocale.currencyCode ?? "USD"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let formattedPrice = formatter.string(from: product.price) ?? "\(product.price)"

        let basePeriod = mapSK1SubscriptionPeriod(period)
        let basePhase = NoctuaPricingPhase(
            formattedPrice: formattedPrice,
            priceAmountMicros: priceMicros,
            priceCurrencyCode: currencyCode,
            billingPeriod: basePeriod,
            recurrenceMode: 1 // infinite recurring
        )

        var offers: [NoctuaSubscriptionOfferDetails] = []

        // Base plan
        let baseOffer = NoctuaSubscriptionOfferDetails(
            basePlanId: product.productIdentifier,
            offerId: nil,
            offerToken: "",
            pricingPhases: [basePhase]
        )
        offers.append(baseOffer)

        // Introductory offer
        if let intro = product.introductoryPrice {
            let introPriceMicros = intro.price.multiplying(by: NSDecimalNumber(value: 1_000_000)).int64Value
            let introFormattedPrice = formatter.string(from: intro.price) ?? "\(intro.price)"
            let introPeriod = mapSK1SubscriptionPeriod(intro.subscriptionPeriod)

            let introPhase = NoctuaPricingPhase(
                formattedPrice: introFormattedPrice,
                priceAmountMicros: introPriceMicros,
                priceCurrencyCode: currencyCode,
                billingPeriod: introPeriod,
                recurrenceMode: intro.numberOfPeriods > 0 ? 2 : 1
            )

            let introOffer = NoctuaSubscriptionOfferDetails(
                basePlanId: product.productIdentifier,
                offerId: "introductory",
                offerToken: "",
                pricingPhases: [introPhase, basePhase]
            )
            offers.append(introOffer)
        }

        // Promotional offers (discounts)
        for discount in product.discounts {
            let discPriceMicros = discount.price.multiplying(by: NSDecimalNumber(value: 1_000_000)).int64Value
            let discFormattedPrice = formatter.string(from: discount.price) ?? "\(discount.price)"
            let discPeriod = mapSK1SubscriptionPeriod(discount.subscriptionPeriod)

            let discPhase = NoctuaPricingPhase(
                formattedPrice: discFormattedPrice,
                priceAmountMicros: discPriceMicros,
                priceCurrencyCode: currencyCode,
                billingPeriod: discPeriod,
                recurrenceMode: discount.numberOfPeriods > 0 ? 2 : 1
            )

            let discOffer = NoctuaSubscriptionOfferDetails(
                basePlanId: product.productIdentifier,
                offerId: discount.identifier,
                offerToken: discount.identifier ?? "",
                pricingPhases: [discPhase, basePhase]
            )
            offers.append(discOffer)
        }

        return offers.isEmpty ? nil : offers
    }

    private func mapSK1SubscriptionPeriod(_ period: SKProductSubscriptionPeriod) -> String {
        switch period.unit {
        case .day:   return "P\(period.numberOfUnits)D"
        case .week:  return "P\(period.numberOfUnits)W"
        case .month: return "P\(period.numberOfUnits)M"
        case .year:  return "P\(period.numberOfUnits)Y"
        @unknown default: return "P\(period.numberOfUnits)D"
        }
    }

    private func mapSKPaymentTransaction(_ transaction: SKPaymentTransaction) -> NoctuaPurchaseResult {
        let productId = transaction.payment.productIdentifier
        let product = cachedProducts[productId]
        let isSubscription = product?.subscriptionPeriod != nil

        // For restored transactions, use the original transaction's info
        let effectiveTransaction = transaction.original ?? transaction

        return NoctuaPurchaseResult(
            success: true,
            errorCode: .ok,
            purchaseState: .purchased,
            productId: productId,
            orderId: effectiveTransaction.transactionIdentifier ?? "",
            purchaseToken: transaction.transactionIdentifier ?? "",
            purchaseTime: Int64((transaction.transactionDate?.timeIntervalSince1970 ?? 0) * 1000),
            isAcknowledged: true, // SK1 purchased state implies acknowledged
            isAutoRenewing: isSubscription,
            quantity: transaction.payment.quantity,
            message: "",
            originalJson: getAppStoreReceipt(),
            transactionJson: "" // SK1 has no per-transaction JWS
        )
    }

    private func doesTransactionMatchType(_ transaction: SKPaymentTransaction, productType: ProductType) -> Bool {
        if let product = cachedProducts[transaction.payment.productIdentifier] {
            let isSubscription = product.subscriptionPeriod != nil
            switch productType {
            case .inapp: return !isSubscription
            case .subs: return isSubscription
            }
        }
        // If product isn't cached, include it (we can't determine type)
        return true
    }

    private func mapSKError(_ error: SKError) -> StoreKitErrorCode {
        switch error.code {
        case .paymentCancelled:
            return .userCanceled
        case .cloudServiceNetworkConnectionFailed:
            return .networkError
        case .storeProductNotAvailable:
            return .itemUnavailable
        case .paymentNotAllowed:
            return .error
        case .paymentInvalid:
            return .developerError
        case .cloudServicePermissionDenied:
            return .serviceUnavailable
        default:
            return .error
        }
    }

    private func cleanupRequest(_ request: SKProductsRequest) {
        activeRequests.removeAll { $0 === request }
    }
}
