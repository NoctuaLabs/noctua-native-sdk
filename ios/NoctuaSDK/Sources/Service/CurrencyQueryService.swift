import Foundation
import StoreKit

/// Lightweight service for querying product currency via SKProductsRequest.
/// This does NOT add any SKPaymentTransactionObserver — it only performs
/// read-only product queries, so it will not conflict with game developers'
/// own IAP implementations.
class CurrencyQueryService: NSObject, SKProductsRequestDelegate {
    private let logger: NoctuaLogger
    private var callbacks: [String: (Bool, String) -> Void] = [:]
    private var activeRequests: [SKProductsRequest] = []

    init(logger: NoctuaLogger = IOSLogger(category: "CurrencyQueryService")) {
        self.logger = logger
        super.init()
    }

    func getActiveCurrency(productId: String, completion: @escaping (Bool, String) -> Void) {
        callbacks[productId] = completion
        let request = SKProductsRequest(productIdentifiers: [productId])
        request.delegate = self
        activeRequests.append(request)
        request.start()
        logger.debug("Started currency query for product: \(productId)")
    }

    // MARK: - SKProductsRequestDelegate

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for product in response.products {
            let productId = product.productIdentifier
            if let callback = callbacks[productId] {
                if let currency = product.priceLocale.currencyCode {
                    logger.debug("Currency for \(productId): \(currency)")
                    callback(true, currency)
                } else {
                    logger.warning("Unable to retrieve currency for \(productId)")
                    callback(false, "Unable to retrieve product currency")
                }
                callbacks.removeValue(forKey: productId)
            }
        }

        // Handle invalid product IDs
        for invalidId in response.invalidProductIdentifiers {
            if let callback = callbacks[invalidId] {
                logger.warning("Invalid product ID: \(invalidId)")
                callback(false, "Invalid product ID: \(invalidId)")
                callbacks.removeValue(forKey: invalidId)
            }
        }

        cleanupRequest(request)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        logger.warning("SKProductsRequest failed: \(error.localizedDescription)")

        // Notify all pending callbacks for this request about the failure
        if let productsRequest = request as? SKProductsRequest {
            // We can't directly get the product IDs from the request,
            // so notify all pending callbacks
            for (productId, callback) in callbacks {
                callback(false, "Request failed: \(error.localizedDescription)")
                callbacks.removeValue(forKey: productId)
            }
            cleanupRequest(productsRequest)
        }
    }

    private func cleanupRequest(_ request: SKProductsRequest) {
        activeRequests.removeAll { $0 === request }
    }
}
