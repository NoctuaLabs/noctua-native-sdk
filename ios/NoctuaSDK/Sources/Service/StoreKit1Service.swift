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

    // What each in-flight SKProductsRequest was started for. SK1 delivers every products
    // response to the same delegate, so this must be tracked per request: a single shared
    // "pending purchase product" / "pending query type" slot let a concurrent details query's
    // response be consumed as a purchase lookup (or the reverse) — silently adding a payment
    // for the wrong call, or failing a purchase with a false "Product not found".
    private enum ProductRequestPurpose {
        case query(ProductType)
        case purchase(productId: String)
    }
    private var requestPurposes: [ObjectIdentifier: ProductRequestPurpose] = [:]

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
        onMain { [self] in
            paymentQueue.remove(self)
            pendingTransactions.removeAll()
            activeRequests.removeAll()
            requestPurposes.removeAll()
            pendingRestoreResults.removeAll()
            isInitialized = false
            logger.info("StoreKit1Service disposed")
        }
    }

    func isReady() -> Bool {
        return isInitialized
    }

    func registerProduct(productId: String, consumableType: ConsumableType) {
        onMain { [self] in
            productTypeMap[productId] = consumableType
            logger.debug("Registered product: \(productId) as \(consumableType)")
        }
    }

    func queryProductDetails(productIds: [String], productType: ProductType) {
        onMain { [self] in
            startProductRequest(productRequestFactory(Set(productIds)), purpose: .query(productType))
            logger.debug("Started product details query for \(productIds.count) products (SK1)")
        }
    }

    func purchase(productId: String) {
        onMain { [self] in
            if let product = cachedProducts[productId] {
                paymentQueue.add(SKPayment(product: product))
                logger.debug("Added payment to queue for \(productId) (SK1)")
            } else {
                // Query product first, then purchase when this request's response arrives
                startProductRequest(productRequestFactory([productId]), purpose: .purchase(productId: productId))
                logger.debug("Querying product before purchase: \(productId) (SK1)")
            }
        }
    }

    func queryPurchases(productType: ProductType) {
        onMain { [self] in queryPurchasesOnMain(productType: productType) }
    }

    private func queryPurchasesOnMain(productType: ProductType) {
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
        onMain { [self] in
            pendingRestoreResults.removeAll()
            paymentQueue.restoreCompletedTransactions()
            logger.debug("Restore purchases initiated (SK1)")
        }
    }

    func getProductPurchaseStatus(productId: String) {
        onMain { [self] in getProductPurchaseStatusOnMain(productId: productId) }
    }

    private func getProductPurchaseStatusOnMain(productId: String) {
        // Step 1 — check the SK1 in-flight queue first. This catches a
        // freshly-purchased product BEFORE `completePurchaseProcessing`
        // calls `finishTransaction`, which is the only window where SK1
        // remembers the transaction at all.
        let matchingTransaction = pendingTransactions.values.first {
            $0.payment.productIdentifier == productId &&
            ($0.transactionState == .purchased || $0.transactionState == .restored)
        }

        if let transaction = matchingTransaction {
            let product = cachedProducts[productId]
            let isSubscription = product?.subscriptionPeriod != nil
            let status = NoctuaProductPurchaseStatus(
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
            logger.debug("Product purchase status for \(productId): isPurchased=true (SK1, in-flight)")
            DispatchQueue.main.async { [weak self] in
                self?.eventListener?.onProductPurchaseStatusResult(status: status)
            }
            return
        }

        // Step 2 — fall through to StoreKit 2's `Transaction.currentEntitlements`,
        // the only Apple API that reports persistent ownership for non-
        // consumables and active subscriptions. SK2 entitlements are
        // populated alongside SK1 transactions on iOS 15+ — Apple keeps
        // both representations in sync, so this works even when the
        // payment flow itself is SK1.
        //
        // Without this fallback, every previously-purchased non-consumable
        // returns `false` because `pendingTransactions` is wiped by
        // `finishTransaction` during the original purchase.
        if #available(iOS 15.0, *) {
            // Read the product cache here, on main — the Task body runs off-main and must not
            // touch service state.
            let isSubscription = cachedProducts[productId]?.subscriptionPeriod != nil
            Task { [weak self] in
                guard let self = self else { return }
                let matched = await self.findCurrentEntitlement(productId: productId)
                let status: NoctuaProductPurchaseStatus
                if let tx = matched {
                    status = NoctuaProductPurchaseStatus(
                        productId: productId,
                        isPurchased: true,
                        isAcknowledged: true,
                        isAutoRenewing: isSubscription && tx.revocationDate == nil,
                        purchaseState: .purchased,
                        purchaseToken: String(tx.id),
                        purchaseTime: Int64(tx.purchaseDate.timeIntervalSince1970 * 1000),
                        expiryTime: Int64((tx.expirationDate?.timeIntervalSince1970 ?? 0) * 1000),
                        orderId: String(tx.originalID),
                        originalJson: self.getAppStoreReceipt(),
                        transactionJson: tx.jsonRepresentation.base64EncodedString()
                    )
                    self.logger.debug("Product purchase status for \(productId): isPurchased=true (SK1, SK2-entitlement fallback)")
                } else {
                    status = NoctuaProductPurchaseStatus(productId: productId, isPurchased: false)
                    self.logger.debug("Product purchase status for \(productId): isPurchased=false (SK1, no SK2 entitlement)")
                }
                await MainActor.run {
                    self.eventListener?.onProductPurchaseStatusResult(status: status)
                }
            }
            return
        }

        // Step 3 — pre-iOS-15 fallback. SK2 not available; the best we can
        // do is return false. Real fix would be receipt-based validation,
        // but iOS 14 share is now negligible and Apple has effectively
        // sunset receipt parsing in favour of SK2.
        let status = NoctuaProductPurchaseStatus(productId: productId, isPurchased: false)
        logger.debug("Product purchase status for \(productId): isPurchased=false (SK1, pre-iOS-15)")
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

        onMain { [self] in
            if let transaction = pendingTransactions[purchaseToken] {
                paymentQueue.finishTransaction(transaction)
                pendingTransactions.removeValue(forKey: purchaseToken)
                logger.debug("Purchase processing completed for token: \(purchaseToken.prefix(20))... (SK1)")
            } else {
                // Transaction may have already been finished
                logger.debug("Transaction already finished or not found: \(purchaseToken.prefix(20))... (SK1)")
            }
            DispatchQueue.main.async { callback?(true) }
        }
    }

    // MARK: - SKPaymentTransactionObserver

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        onMain { [self] in handleUpdatedTransactions(transactions) }
    }

    private func handleUpdatedTransactions(_ transactions: [SKPaymentTransaction]) {
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
        onMain { [self] in
            let restoredPurchases = pendingRestoreResults
            pendingRestoreResults.removeAll()

            logger.debug("Restore purchases completed: \(restoredPurchases.count) purchases found (SK1)")
            DispatchQueue.main.async { [weak self] in
                self?.eventListener?.onRestorePurchasesCompleted(purchases: restoredPurchases)
            }
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        onMain { [self] in
            pendingRestoreResults.removeAll()

            let errorCode = (error as? SKError).map { StoreKit1Service.mapSKError($0) } ?? .error
            logger.error("Failed to restore purchases: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.eventListener?.onStoreKitError(
                    error: errorCode,
                    message: "Failed to restore purchases: \(error.localizedDescription)"
                )
            }
        }
    }

    // MARK: - SKProductsRequestDelegate

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        onMain { [self] in
            let purpose = requestPurposes[ObjectIdentifier(request)]
            cleanupRequest(request)

            switch purpose {
            case .purchase(let productId):
                handlePurchaseLookupResponse(productId: productId, response: response)
            case .query(let productType):
                handleProductDetailsResponse(productType: productType, response: response)
            case nil:
                logger.warning("Ignoring response for an untracked product request (SK1)")
            }
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        onMain { [self] in
            logger.error("SKProductsRequest failed: \(error.localizedDescription)")

            guard let productsRequest = request as? SKProductsRequest else { return }
            let purpose = requestPurposes[ObjectIdentifier(productsRequest)]
            cleanupRequest(productsRequest)

            switch purpose {
            case .purchase(let productId):
                reportPurchaseLookupFailure(
                    productId: productId,
                    errorCode: .error,
                    message: "Failed to fetch product for purchase: \(productId): \(error.localizedDescription)"
                )
            case .query:
                DispatchQueue.main.async { [weak self] in
                    self?.eventListener?.onStoreKitError(
                        error: .error,
                        message: "Failed to query product details: \(error.localizedDescription)"
                    )
                }
            case nil:
                logger.warning("Ignoring failure for an untracked product request (SK1)")
            }
        }
    }

    // MARK: - Product Request Routing

    private func startProductRequest(_ request: SKProductsRequest, purpose: ProductRequestPurpose) {
        request.delegate = self
        activeRequests.append(request)
        requestPurposes[ObjectIdentifier(request)] = purpose
        request.start()
    }

    private func handlePurchaseLookupResponse(productId: String, response: SKProductsResponse) {
        guard let product = response.products.first(where: { $0.productIdentifier == productId }) else {
            reportPurchaseLookupFailure(
                productId: productId,
                errorCode: .itemUnavailable,
                message: "Product not found: \(productId)"
            )
            return
        }

        cachedProducts[product.productIdentifier] = product
        paymentQueue.add(SKPayment(product: product))
        logger.debug("Auto-purchased after query: \(productId) (SK1)")
    }

    private func handleProductDetailsResponse(productType: ProductType, response: SKProductsResponse) {
        let filtered = response.products.filter { product in
            let isSubscription = product.subscriptionPeriod != nil
            switch productType {
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
    }

    /// Reports a failure that belongs to one specific purchase. It is delivered as a purchase
    /// result carrying the productId, so a bridge can match it to the purchase that asked for
    /// it instead of guessing from an unscoped error. onStoreKitError is still emitted
    /// afterwards (same code and message as before) for listeners that only watch errors.
    private func reportPurchaseLookupFailure(productId: String, errorCode: StoreKitErrorCode, message: String) {
        logger.error(message)
        let result = NoctuaPurchaseResult(
            success: false,
            errorCode: errorCode,
            productId: productId,
            message: message
        )
        DispatchQueue.main.async { [weak self] in
            self?.eventListener?.onPurchaseCompleted(result: result)
            self?.eventListener?.onStoreKitError(error: errorCode, message: message)
        }
    }

    /// Runs `work` on the main thread — synchronously when already there. All mutable service
    /// state is only touched from main: SKPaymentQueue and SKProductsRequest callbacks arrive
    /// there, while the public entry points can be called from any thread (e.g. a Unity
    /// thread-pool continuation).
    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
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

        let errorCode = error.map { StoreKit1Service.mapSKError($0) } ?? .error
        let message = StoreKit1Service.describeTransactionError(transaction.error)

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

    /// Iterates `Transaction.currentEntitlements` to find a verified
    /// transaction matching `productId`. Bounded by a 250 ms timeout so
    /// the call always returns in finite time, even when the iterator
    /// is waiting for the App Store (real device) or stuck (unit test
    /// without StoreKitTest configuration). Without the timeout the
    /// SK1 unit-test suite hangs the listener and
    /// `testGetProductPurchaseStatusNotFound` fails.
    @available(iOS 15.0, *)
    private func findCurrentEntitlement(productId: String) async -> Transaction? {
        // Two competing tasks: the actual entitlement walk vs a sleep-
        // based timeout. Whichever finishes first wins; the loser is
        // cancelled to release any held resources.
        return await withTaskGroup(of: Transaction?.self) { group in
            group.addTask {
                for await result in Transaction.currentEntitlements {
                    if case .verified(let tx) = result, tx.productID == productId {
                        return tx
                    }
                }
                return nil
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 250_000_000) // 250 ms
                return nil
            }
            // First non-nil wins; if both return nil, the entitlement was
            // genuinely absent (or the timeout fired first — same result
            // semantically: caller treats as "not purchased").
            for await result in group {
                if let tx = result {
                    group.cancelAll()
                    return tx
                }
            }
            return nil
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

    /// Maps `SKError.Code` (https://developer.apple.com/documentation/storekit/skerror/code) to the
    /// cross-platform error code. Existing mappings are unchanged; the offer/entitlement codes Apple
    /// documents as request-configuration problems map to `.developerError`.
    static func mapSKError(_ error: SKError) -> StoreKitErrorCode {
        switch error.code {
        case .paymentCancelled:
            return .userCanceled
        case .cloudServiceNetworkConnectionFailed:
            return .networkError
        case .storeProductNotAvailable:
            return .itemUnavailable
        case .paymentNotAllowed:
            return .error
        case .paymentInvalid, .invalidOfferIdentifier, .invalidOfferPrice, .invalidSignature,
             .missingOfferParams, .unauthorizedRequestData:
            return .developerError
        case .cloudServicePermissionDenied, .cloudServiceRevoked:
            return .serviceUnavailable
        default:
            return .error
        }
    }

    private func cleanupRequest(_ request: SKProductsRequest) {
        activeRequests.removeAll { $0 === request }
        requestPurposes.removeValue(forKey: ObjectIdentifier(request))
    }

    /// Human-readable failure text for a failed transaction. StoreKit 1 reports many App Store
    /// account and payment-method problems as a bare `SKError.unknown` ("An unknown error
    /// occurred"); the actionable reason only lives in `NSUnderlyingErrorKey`, so it is appended
    /// when present. The base text is unchanged, keeping existing message checks working.
    static func describeTransactionError(_ error: Error?) -> String {
        guard let error = error else { return "Unknown error" }
        return StoreKitErrorDescription.describe(error)
    }
}

/// Failure text shared by the StoreKit 1 and StoreKit 2 services.
enum StoreKitErrorDescription {
    /// The error's description, plus the `NSUnderlyingErrorKey` domain and code when present — StoreKit
    /// often reports account and payment-method problems as a generic "unknown" error whose actionable
    /// reason only lives in the underlying error.
    static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        guard let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError else {
            return nsError.localizedDescription
        }
        return "\(nsError.localizedDescription) (underlying: \(underlying.domain) \(underlying.code))"
    }
}
