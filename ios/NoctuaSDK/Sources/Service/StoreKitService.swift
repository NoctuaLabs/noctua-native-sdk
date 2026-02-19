import Foundation
import StoreKit

@available(iOS 15.0, *)
class StoreKitService: StoreKitServiceProtocol {
    private let logger: NoctuaLogger
    private let config: NoctuaStoreKitConfig
    private weak var eventListener: StoreKitEventListener?
    private var productTypeMap: [String: ConsumableType] = [:]
    private var transactionListenerTask: Task<Void, Never>?
    private var cachedProducts: [String: Product] = [:]
    private var isInitialized = false

    init(config: NoctuaStoreKitConfig, logger: NoctuaLogger = IOSLogger(category: "StoreKitService")) {
        self.config = config
        self.logger = logger
    }

    // MARK: - StoreKitServiceProtocol

    func initialize(listener: StoreKitEventListener?) {
        guard !isInitialized else {
            logger.warning("StoreKitService already initialized")
            return
        }

        self.eventListener = listener
        transactionListenerTask = listenForTransactions()
        isInitialized = true

        // Query existing purchases on initialization
        queryExistingPurchases()

        logger.info("StoreKitService initialized (StoreKit 2)")
    }

    func dispose() {
        transactionListenerTask?.cancel()
        transactionListenerTask = nil
        isInitialized = false
        logger.info("StoreKitService disposed")
    }

    func isReady() -> Bool {
        return isInitialized
    }

    func registerProduct(productId: String, consumableType: ConsumableType) {
        productTypeMap[productId] = consumableType
        logger.debug("Registered product: \(productId) as \(consumableType)")
    }

    func queryProductDetails(productIds: [String], productType: ProductType) {
        Task {
            do {
                let products = try await Product.products(for: Set(productIds))

                let filtered = products.filter { product in
                    switch productType {
                    case .inapp:
                        return product.type == .consumable || product.type == .nonConsumable
                    case .subs:
                        return product.type == .autoRenewable || product.type == .nonRenewable
                    }
                }

                // Cache products
                for product in filtered {
                    cachedProducts[product.id] = product
                }

                let results = filtered.map { mapProduct($0) }
                logger.debug("Loaded \(results.count) product details")

                await MainActor.run {
                    self.eventListener?.onProductDetailsLoaded(products: results)
                }
            } catch {
                logger.error("Failed to query product details: \(error.localizedDescription)")
                await MainActor.run {
                    self.eventListener?.onStoreKitError(
                        error: .error,
                        message: "Failed to query product details: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    func purchase(productId: String) {
        Task {
            await purchaseAsync(productId: productId)
        }
    }

    func queryPurchases(productType: ProductType) {
        Task {
            var purchases: [NoctuaPurchaseResult] = []

            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    let matchesType = doesTransactionMatchType(transaction, productType: productType)
                    if matchesType {
                        purchases.append(mapTransaction(transaction))
                    }
                }
            }

            let finalResults = purchases
            logger.debug("Queried \(finalResults.count) purchases for type \(productType)")
            await MainActor.run {
                self.eventListener?.onQueryPurchasesCompleted(purchases: finalResults)
            }
        }
    }

    func restorePurchases() {
        Task {
            do {
                try await AppStore.sync()

                var allPurchases: [NoctuaPurchaseResult] = []

                for await result in Transaction.currentEntitlements {
                    if case .verified(let transaction) = result {
                        allPurchases.append(mapTransaction(transaction))

                        // Process unfinished transactions
                        let consumableType = productTypeMap[transaction.productID] ?? .nonConsumable
                        if config.verifyPurchasesOnServer {
                            await MainActor.run {
                                self.eventListener?.onServerVerificationRequired(
                                    result: self.mapTransaction(transaction),
                                    consumableType: consumableType
                                )
                            }
                        } else {
                            await transaction.finish()
                        }
                    }
                }

                let finalPurchases = allPurchases
                logger.debug("Restore purchases completed: \(finalPurchases.count) purchases found")
                await MainActor.run {
                    self.eventListener?.onRestorePurchasesCompleted(purchases: finalPurchases)
                }
            } catch {
                logger.error("Failed to restore purchases: \(error.localizedDescription)")
                await MainActor.run {
                    self.eventListener?.onStoreKitError(
                        error: .error,
                        message: "Failed to restore purchases: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    func getProductPurchaseStatus(productId: String) {
        Task {
            var matchingTransaction: Transaction?

            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.productID == productId {
                        matchingTransaction = transaction
                        break
                    }
                }
            }

            let status: NoctuaProductPurchaseStatus
            if let transaction = matchingTransaction {
                let productType = cachedProducts[productId]?.type
                status = NoctuaProductPurchaseStatus(
                    productId: productId,
                    isPurchased: true,
                    isAcknowledged: true,
                    isAutoRenewing: productType == .autoRenewable && transaction.revocationDate == nil,
                    purchaseState: .purchased,
                    purchaseToken: String(transaction.id),
                    purchaseTime: Int64(transaction.purchaseDate.timeIntervalSince1970 * 1000),
                    orderId: String(transaction.originalID),
                    originalJson: transaction.jsonRepresentation.base64EncodedString()
                )
            } else {
                status = NoctuaProductPurchaseStatus(
                    productId: productId,
                    isPurchased: false
                )
            }

            logger.debug("Product purchase status for \(productId): isPurchased=\(status.isPurchased)")
            await MainActor.run {
                self.eventListener?.onProductPurchaseStatusResult(status: status)
            }
        }
    }

    func completePurchaseProcessing(purchaseToken: String, consumableType: ConsumableType, verified: Bool, callback: ((Bool) -> Void)?) {
        guard verified else {
            logger.warning("Server verification failed for token: \(purchaseToken.prefix(20))...")
            callback?(false)
            return
        }

        Task {
            // Find the transaction by ID and finish it
            guard let transactionId = UInt64(purchaseToken) else {
                logger.error("Invalid purchase token format: \(purchaseToken)")
                await MainActor.run { callback?(false) }
                return
            }

            // Try to find the unfinished transaction
            for await result in Transaction.unfinished {
                if case .verified(let transaction) = result {
                    if transaction.id == transactionId {
                        await transaction.finish()
                        logger.debug("Purchase processing completed for token: \(purchaseToken.prefix(20))...")
                        await MainActor.run { callback?(true) }
                        return
                    }
                }
            }

            // Transaction may have already been finished
            logger.debug("Transaction already finished or not found: \(purchaseToken.prefix(20))...")
            await MainActor.run { callback?(true) }
        }
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }

                switch result {
                case .verified(let transaction):
                    let purchaseResult = self.mapTransaction(transaction)
                    self.logger.debug("Transaction update: \(transaction.productID), state: verified")

                    await self.handleVerifiedTransaction(transaction, result: purchaseResult)

                    await MainActor.run {
                        self.eventListener?.onPurchaseUpdated(result: purchaseResult)
                    }

                case .unverified(let transaction, let error):
                    self.logger.error("Unverified transaction: \(transaction.productID), error: \(error.localizedDescription)")
                    let errorResult = NoctuaPurchaseResult(
                        success: false,
                        errorCode: .error,
                        productId: transaction.productID,
                        message: "Transaction verification failed: \(error.localizedDescription)"
                    )
                    await MainActor.run {
                        self.eventListener?.onPurchaseUpdated(result: errorResult)
                    }
                }
            }
        }
    }

    private func purchaseAsync(productId: String) async {
        // Fetch product if not cached
        var product = cachedProducts[productId]
        if product == nil {
            do {
                let products = try await Product.products(for: [productId])
                product = products.first
                if let product = product {
                    cachedProducts[productId] = product
                }
            } catch {
                logger.error("Failed to fetch product \(productId): \(error.localizedDescription)")
                await MainActor.run {
                    self.eventListener?.onStoreKitError(
                        error: .itemUnavailable,
                        message: "Failed to fetch product: \(error.localizedDescription)"
                    )
                }
                return
            }
        }

        guard let product = product else {
            logger.error("Product not found: \(productId)")
            await MainActor.run {
                self.eventListener?.onStoreKitError(
                    error: .itemUnavailable,
                    message: "Product not found: \(productId)"
                )
            }
            return
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    let purchaseResult = mapTransaction(transaction)

                    await handleVerifiedTransaction(transaction, result: purchaseResult)

                    await MainActor.run {
                        self.eventListener?.onPurchaseCompleted(result: purchaseResult)
                    }

                case .unverified(let transaction, let error):
                    logger.warning("Purchase unverified: \(error.localizedDescription)")
                    let purchaseResult = NoctuaPurchaseResult(
                        success: false,
                        errorCode: .error,
                        purchaseState: .purchased,
                        productId: transaction.productID,
                        purchaseToken: String(transaction.id),
                        message: "Transaction verification failed: \(error.localizedDescription)"
                    )
                    await MainActor.run {
                        self.eventListener?.onPurchaseCompleted(result: purchaseResult)
                    }
                }

            case .pending:
                logger.info("Purchase pending for \(productId)")
                let purchaseResult = NoctuaPurchaseResult(
                    success: false,
                    purchaseState: .pending,
                    productId: productId,
                    message: "Purchase is pending approval"
                )
                await MainActor.run {
                    self.eventListener?.onPurchaseCompleted(result: purchaseResult)
                }

            case .userCancelled:
                logger.info("User cancelled purchase for \(productId)")
                let purchaseResult = NoctuaPurchaseResult(
                    success: false,
                    errorCode: .userCanceled,
                    productId: productId,
                    message: "User cancelled"
                )
                await MainActor.run {
                    self.eventListener?.onPurchaseCompleted(result: purchaseResult)
                }

            @unknown default:
                logger.warning("Unknown purchase result for \(productId)")
                let purchaseResult = NoctuaPurchaseResult(
                    success: false,
                    errorCode: .error,
                    productId: productId,
                    message: "Unknown purchase result"
                )
                await MainActor.run {
                    self.eventListener?.onPurchaseCompleted(result: purchaseResult)
                }
            }
        } catch {
            logger.error("Purchase failed: \(error.localizedDescription)")
            let errorCode = mapStoreKitError(error)
            let purchaseResult = NoctuaPurchaseResult(
                success: false,
                errorCode: errorCode,
                productId: productId,
                message: "Purchase failed: \(error.localizedDescription)"
            )
            await MainActor.run {
                self.eventListener?.onPurchaseCompleted(result: purchaseResult)
            }
        }
    }

    private func handleVerifiedTransaction(_ transaction: Transaction, result: NoctuaPurchaseResult) async {
        let consumableType = productTypeMap[transaction.productID] ?? .nonConsumable

        if config.verifyPurchasesOnServer {
            logger.debug("Server verification required for \(transaction.productID) (type: \(consumableType))")
            await MainActor.run {
                self.eventListener?.onServerVerificationRequired(
                    result: result,
                    consumableType: consumableType
                )
            }
        } else {
            await transaction.finish()
            logger.debug("Transaction finished for \(transaction.productID)")
        }
    }

    private func queryExistingPurchases() {
        queryPurchases(productType: .inapp)
        queryPurchases(productType: .subs)
    }

    // MARK: - Mapping Helpers

    private func mapProduct(_ product: Product) -> NoctuaProductDetails {
        let productType: ProductType = (product.type == .autoRenewable || product.type == .nonRenewable) ? .subs : .inapp
        let priceMicros = NSDecimalNumber(decimal: product.price).multiplying(by: NSDecimalNumber(value: 1_000_000)).int64Value

        return NoctuaProductDetails(
            productId: product.id,
            title: product.displayName,
            productDescription: product.description,
            formattedPrice: product.displayPrice,
            priceAmountMicros: priceMicros,
            priceCurrencyCode: product.priceFormatStyle.currencyCode,
            productType: productType,
            subscriptionOfferDetails: mapSubscriptionOffers(product)
        )
    }

    private func mapSubscriptionOffers(_ product: Product) -> [NoctuaSubscriptionOfferDetails]? {
        guard product.type == .autoRenewable,
              let subscription = product.subscription else {
            return nil
        }

        // Map the base subscription as an offer
        let basePeriod = mapSubscriptionPeriod(subscription.subscriptionPeriod)
        let basePriceMicros = NSDecimalNumber(decimal: product.price).multiplying(by: NSDecimalNumber(value: 1_000_000)).int64Value

        let basePhase = NoctuaPricingPhase(
            formattedPrice: product.displayPrice,
            priceAmountMicros: basePriceMicros,
            priceCurrencyCode: product.priceFormatStyle.currencyCode,
            billingPeriod: basePeriod,
            recurrenceMode: 1 // infinite recurring
        )

        var offers: [NoctuaSubscriptionOfferDetails] = []

        // Base plan
        let baseOffer = NoctuaSubscriptionOfferDetails(
            basePlanId: product.id,
            offerId: nil,
            offerToken: "",
            pricingPhases: [basePhase]
        )
        offers.append(baseOffer)

        // Promotional offers
        let promotionalOffers = subscription.promotionalOffers
        if !promotionalOffers.isEmpty {
            for offer in promotionalOffers {
                let offerPriceMicros = NSDecimalNumber(decimal: offer.price).multiplying(by: NSDecimalNumber(value: 1_000_000)).int64Value
                let offerPeriod = mapSubscriptionPeriod(offer.period)

                let phase = NoctuaPricingPhase(
                    formattedPrice: offer.displayPrice,
                    priceAmountMicros: offerPriceMicros,
                    priceCurrencyCode: product.priceFormatStyle.currencyCode,
                    billingPeriod: offerPeriod,
                    recurrenceMode: offer.periodCount > 0 ? 2 : 1
                )

                let subOffer = NoctuaSubscriptionOfferDetails(
                    basePlanId: product.id,
                    offerId: offer.id,
                    offerToken: offer.id ?? "",
                    pricingPhases: [phase, basePhase]
                )
                offers.append(subOffer)
            }
        }

        return offers.isEmpty ? nil : offers
    }

    private func mapTransaction(_ transaction: Transaction) -> NoctuaPurchaseResult {
        let productType = cachedProducts[transaction.productID]?.type
        let isAutoRenewing = productType == .autoRenewable && transaction.revocationDate == nil

        return NoctuaPurchaseResult(
            success: true,
            errorCode: .ok,
            purchaseState: .purchased,
            productId: transaction.productID,
            orderId: String(transaction.originalID),
            purchaseToken: String(transaction.id),
            purchaseTime: Int64(transaction.purchaseDate.timeIntervalSince1970 * 1000),
            isAcknowledged: transaction.revocationDate == nil,
            isAutoRenewing: isAutoRenewing,
            quantity: transaction.purchasedQuantity,
            message: "",
            originalJson: transaction.jsonRepresentation.base64EncodedString()
        )
    }

    private func mapSubscriptionPeriod(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            return "P\(period.value)D"
        case .week:
            return "P\(period.value)W"
        case .month:
            return "P\(period.value)M"
        case .year:
            return "P\(period.value)Y"
        @unknown default:
            return "P\(period.value)D"
        }
    }

    private func doesTransactionMatchType(_ transaction: Transaction, productType: ProductType) -> Bool {
        if let product = cachedProducts[transaction.productID] {
            switch productType {
            case .inapp:
                return product.type == .consumable || product.type == .nonConsumable
            case .subs:
                return product.type == .autoRenewable || product.type == .nonRenewable
            }
        }
        // If product isn't cached, include it (we can't determine type)
        return true
    }

    private func mapStoreKitError(_ error: Error) -> StoreKitErrorCode {
        if let storeKitError = error as? StoreKitError {
            switch storeKitError {
            case .userCancelled:
                return .userCanceled
            case .networkError:
                return .networkError
            case .notAvailableInStorefront:
                return .itemUnavailable
            case .notEntitled:
                return .itemNotOwned
            default:
                return .error
            }
        }
        return .error
    }
}
