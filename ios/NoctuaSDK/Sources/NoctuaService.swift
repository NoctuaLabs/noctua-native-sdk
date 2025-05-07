import Foundation
import os
import StoreKit

public typealias CompletionCallback = (Bool, String) -> Void

struct NoctuaServiceConfig: Decodable {
    let iapDisabled: Bool?
}

class NoctuaService: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    private var productCallbacks: [String: CompletionCallback] = [:]
    private var currencyCallbacks: [String: CompletionCallback] = [:]
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
            request.delegate = self
            request.start()
        } else {
            logger.info("User can't make payments")
            completion(false, "User can't make payments")
        }
    }

    // MARK: - SKProductsRequestDelegate
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for product in response.products {
            let productId = product.productIdentifier

            if let purchaseCallback = productCallbacks[productId] {
                // Handle purchase flow
                logger.info("Found product for purchase: \(productId)")
                let payment = SKPayment(product: product)
                SKPaymentQueue.default().add(payment)
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
            }
        }

        if response.products.isEmpty, let productId = response.invalidProductIdentifiers.first {
            currencyCallbacks[productId]?(false, "Product not found")
            productCallbacks[productId]?(false, "Product not found")
            currencyCallbacks.removeValue(forKey: productId)
            productCallbacks.removeValue(forKey: productId)
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
}
