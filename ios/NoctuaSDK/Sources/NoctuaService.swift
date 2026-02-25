import Foundation
import os
import StoreKit

public typealias CompletionCallback = (Bool, String) -> Void

struct NoctuaServiceConfig: Decodable {
    let iapDisabled: Bool?
    let nativeInternalTrackerEnabled: Bool?
}

class NoctuaService: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    private var productCallbacks: [String: CompletionCallback] = [:]
    private var currencyCallbacks: [String: CompletionCallback] = [:]
    private var requestProductIdMap: [SKRequest: Set<String>] = [:]
    private var noctuaConfig: NoctuaServiceConfig?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: NoctuaService.self)
    )

    var iapDisabled: Bool {
        noctuaConfig?.iapDisabled ?? false
    }

    init(config: NoctuaServiceConfig) {
        super.init()
        noctuaConfig = config
        
        logger.debug("Disable IAP is : \(self.iapDisabled)")

        if !iapDisabled {
            SKPaymentQueue.default().add(self)
        } else {
            logger.info("Noctua SDK Native: IAP is disabled by config")
        }
    }

    func getActiveCurrency(productId: String, completion: @escaping CompletionCallback) {
        currencyCallbacks[productId] = completion
        let request = SKProductsRequest(productIdentifiers: [productId])
        requestProductIdMap[request] = [productId]
        request.delegate = self
        request.start()
    }

    func purchaseItem(productId: String, completion: @escaping CompletionCallback) {
        guard !iapDisabled else {
            completion(false, "IAP is disabled by config")
            return
        }

        logger.info("Noctua SDK Native: purchaseItem called with productId: \(productId)")
        productCallbacks[productId] = completion

        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers: [productId])
            requestProductIdMap[request] = [productId]
            request.delegate = self
            request.start()
        } else {
            logger.info("User can't make payments")
            completion(false, "User can't make payments")
        }
    }

    // MARK: - SKProductsRequestDelegate
    func request(_ request: SKRequest, didFailWithError error: Error) {
        logger.warning("SKProductsRequest failed: \(error.localizedDescription)")

        let requestedIds = requestProductIdMap.removeValue(forKey: request) ?? []

        for productId in requestedIds {
            if let callback = currencyCallbacks.removeValue(forKey: productId) {
                callback(false, "Product request failed: \(error.localizedDescription)")
            }
            if let callback = productCallbacks.removeValue(forKey: productId) {
                callback(false, "Product request failed: \(error.localizedDescription)")
            }
        }
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let requestedIds = requestProductIdMap.removeValue(forKey: request) ?? []
        var handledIds = Set<String>()

        for product in response.products {
            let productId = product.productIdentifier

            if let purchaseCallback = productCallbacks[productId] {
                // Handle purchase flow
                logger.info("Found product for purchase: \(productId)")
                let payment = SKPayment(product: product)
                SKPaymentQueue.default().add(payment)
                // Note: productCallbacks is NOT removed here, it will be resolved in paymentQueue delegate
                handledIds.insert(productId)
            } else if let currencyCallback = currencyCallbacks[productId] {
                // Handle currency query
                if let currency = product.priceLocale.currencyCode {
                    logger.info("Product currency: \(currency)")
                    currencyCallback(true, currency)
                } else {
                    logger.warning("Unable to retrieve product currency")
                    currencyCallback(false, "Unable to retrieve product currency")
                }
                currencyCallbacks.removeValue(forKey: productId)
                handledIds.insert(productId)
            }
        }

        // Handle all invalid product identifiers
        for productId in response.invalidProductIdentifiers {
            if let callback = currencyCallbacks.removeValue(forKey: productId) {
                callback(false, "Product not found: \(productId)")
                handledIds.insert(productId)
            }
            if let callback = productCallbacks.removeValue(forKey: productId) {
                callback(false, "Product not found: \(productId)")
                handledIds.insert(productId)
            }
        }

        // Safety net: if any requested productIds were not resolved by the response
        // (e.g. empty products + empty invalidProductIdentifiers), call them back with error
        for productId in requestedIds where !handledIds.contains(productId) {
            if let callback = currencyCallbacks.removeValue(forKey: productId) {
                logger.warning("Currency callback for \(productId) was not resolved by the product response")
                callback(false, "Product not found: \(productId)")
            }
            if let callback = productCallbacks.removeValue(forKey: productId) {
                logger.warning("Product callback for \(productId) was not resolved by the product response")
                callback(false, "Product not found: \(productId)")
            }
        }
    }

    // MARK: - SKPaymentTransactionObserver
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        guard !iapDisabled else {
            logger.info("paymentQueue(_:updatedTransactions:) was called, but Noctua SDK IAP is disabled via config. Skipping transaction handling.")
            return
        }

        for transaction in transactions {
            let productId = transaction.payment.productIdentifier
            guard let callback = productCallbacks[productId] else {
                logger.warning("No callback for transaction: \(productId)")
                continue
            }

            switch transaction.transactionState {
            case .purchased, .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                handleReceipt(for: transaction, callback: callback)
                productCallbacks.removeValue(forKey: productId)

            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                if let error = transaction.error as? SKError {
                    logger.warning("Payment failed: \(error.localizedDescription)")
                    callback(false, "Payment failed: \(error.localizedDescription)")
                } else {
                    callback(false, "Payment failed")
                }
                productCallbacks.removeValue(forKey: productId)

            case .deferred:
                logger.warning("Payment deferred")
                callback(false, "Payment deferred")

            case .purchasing:
                // In progress; do nothing.
                logger.warning("Transaction in progress")
                break

            @unknown default:
                logger.warning("Unknown transaction state")
                break
            }
        }
    }

    private func handleReceipt(for transaction: SKPaymentTransaction, callback: CompletionCallback) {
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                let receiptString = receiptData.base64EncodedString()
                logger.info("Transaction successful, receipt: \(receiptString.prefix(50))...")
                callback(true, receiptString)
            } catch {
                logger.warning("Couldn't read receipt data: \(error.localizedDescription)")
                callback(false, "Couldn't read receipt data: \(error.localizedDescription)")
            }
        } else {
            logger.warning("Transaction succeeded, but no receipt data available")
            callback(false, "Transaction succeeded, but no receipt data available")
        }
    }
    
    func getProductPurchasedById(id productId: String, completion: @escaping (Bool) -> Void) async {
        if #available(iOS 15.0, *) {
            let purchased = await self.getProductPurchasedStoreKit2(id: productId)
            completion(purchased)
        } else {
            // StoreKit 1 does not provide a reliable way to check purchase status on-device.
            // For older iOS versions, verify the receipt with your server-side backend instead.
            // to get the receipt use getReceiptProductPurchasedStoreKit1(id: productId)
            
            completion(false)
            logger.warning("Unable to verify product purchase on iOS versions below 15.0")
        }
    }
    
    @available(iOS 15.0, *)
    private func getProductPurchasedStoreKit2(id productId: String) async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productId {
                    return true
                }
            }
        }
        return false
    }
    
    
    func getReceiptProductPurchasedStoreKit1(id productId: String, completion: @escaping (String) -> Void) {
        guard let appStoreReceiptUrl = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: appStoreReceiptUrl) else {
            return completion("")
        }
        
        let receiptString = receiptData.base64EncodedString(options: [])
        
        logger.info("Product receipt: \(receiptString.prefix(50))...")
        
        completion(receiptString)
    }
}
