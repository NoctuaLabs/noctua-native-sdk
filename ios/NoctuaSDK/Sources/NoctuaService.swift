import Foundation
import os
import StoreKit

public typealias CompletionCallback = (Bool, String) -> Void

struct NoctuaServiceConfig : Decodable {
    let noctua: NoctuaServiceConfigNoctua
    
    struct NoctuaServiceConfigNoctua : Decodable {
        let disableIAP: Bool
    }
}

class NoctuaService: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    // Used to differentiate between different StoreKit operation
    private var storeKitOperation: String? = nil
    // One StoreKit operation at a time
    private var completionHandler: CompletionCallback? = nil

    private var noctuaConfig: NoctuaServiceConfig
    
    init(config: NoctuaServiceConfig) throws {
        self.noctuaConfig = config
        super.init()

        if (!noctuaConfig.noctua.disableIAP) {
            SKPaymentQueue.default().add(self)
        }
    }
    
    func getActiveCurrency(productId: String, completion: @escaping CompletionCallback) {
        completionHandler = completion
        storeKitOperation = "getActiveCurrency"
        let request = SKProductsRequest(productIdentifiers: Set([productId]))
        request.delegate = self
        request.start() // continue to productsRequest
    }

    func purchaseItem(productId: String, completion: @escaping CompletionCallback) {
        if (noctuaConfig.noctua.disableIAP) {
            completion(false, "IAP is disabled by config")
            return
        }

        completionHandler = completion
        storeKitOperation = "purchaseItem"
        self.logger.info("Noctua SDK Native: NoctuaService.purchaseItem called with productId: \(productId)")	
        initiatePayment(productId: productId, completion: { (success, message) in
            self.logger.info("purchaseItem: \(success), \(message)")
            completion(success, message)
        })
    }
    
    private func initiatePayment(productId: String, completion: @escaping CompletionCallback) {
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers: Set([productId]))
            request.delegate = self
            request.start() // continue to productsRequest
        } else {
            // Handle the case where the user can't make payments
            self.logger.info("User can't make payments")
            completion(false, "User can't make payments")
        }
    }

    // SKProduct related handler. This handler covers both queryProduct and purchaseItem
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let completion = completionHandler!
        self.logger.info("productsRequest: \(response.products)")
        if let product = response.products.first {
            if (storeKitOperation == "purchaseItem") {
                let payment = SKPayment(product: product)
                SKPaymentQueue.default().add(payment) // continue to paymentQueue
            } else if (storeKitOperation == "getActiveCurrency") {
                if let currency = product.priceLocale.currencyCode {
                    self.logger.info("Product currency: \(currency)")
                    completion(true, String(currency))
                } else {
                    self.logger.warning("Unable to retrieve product currency")
                    completion(false, "Unable to retrieve product currency")
                }
            }
        } else {
            self.logger.warning("Product not found")
            if let productId = response.invalidProductIdentifiers.first {
                completion(false, "Product not found")
            }
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        if (noctuaConfig.noctua.disableIAP) {
            return
        }

        guard let completion = completionHandler else {
            self.logger.warning("completion handler is null")
            return
        }

        guard let operation = storeKitOperation, !operation.isEmpty else {
            self.logger.warning("storeKitOperation is empty")
            return
        }

        for transaction in transactions {
            if let error = transaction.error as? SKError {
                switch error.code {
                case .paymentCancelled:
                    self.logger.warning("Payment cancelled")
                    completion(false, "Payment cancelled")
                case .paymentInvalid:
                    self.logger.warning("Payment invalid")
                    completion(false, "Invalid payment")
                case .paymentNotAllowed:
                    self.logger.warning("Payment not allowed")
                    completion(false, "Payment not allowed")
                default:
                    self.logger.warning("Other payment error: \(error.localizedDescription)")
                    completion(false, "error: \(error.localizedDescription)")
                }
            } else if let error = transaction.error as NSError? {
                if error.domain == "ASDErrorDomain" && error.code == 907 {
                    if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError,
                       underlyingError.domain == "AMSErrorDomain" && underlyingError.code == 6 {
                        self.logger.warning("Payment sheet cancelled")
                        completion(false, "Payment sheet cancelled")
                    } else {
                        self.logger.warning("ASDErrorDomain error: \(error.localizedDescription)")
                        completion(false, "Payment error: \(error.localizedDescription)")
                    }
                } else {
                    self.logger.warning("Other error: \(error.localizedDescription)")
                    completion(false, "Payment error: \(error.localizedDescription)")
                }
            } else {
                switch transaction.transactionState {
                case .purchased:
                    SKPaymentQueue.default().finishTransaction(transaction)
                    if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
                       FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
                        do {
                            let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                            let receiptString = receiptData.base64EncodedString(options: [])
                            self.logger.warning("Transaction successful, receiptData: \(receiptString)")
                            completion(true, receiptString)
                        } catch {
                            self.logger.warning("Couldn't read receipt data: \(error)")
                            completion(false, "Couldn't read receipt data: \(error.localizedDescription)")
                        }
                    } else {
                        self.logger.warning("Transaction successful, but no receipt data available")
                        completion(false, "Transaction successful, but no receipt data available")
                    }
                case .failed:
                    self.logger.warning("Transaction failed: \(String(describing: transaction.error?.localizedDescription))")
                    SKPaymentQueue.default().finishTransaction(transaction)
                    completion(false, "failed: \(String(describing: transaction.error?.localizedDescription))")
                case .restored:
                    self.logger.warning("Transaction restored")
                    SKPaymentQueue.default().finishTransaction(transaction)
                    if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
                       FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
                        do {
                            let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                            let receiptString = receiptData.base64EncodedString(options: [])
                            self.logger.warning("Transaction restored, receiptData: \(receiptString)")
                            completion(true, receiptString)
                        } catch {
                            self.logger.warning("Couldn't read receipt data: \(error)")
                            completion(false, "Couldn't read receipt data: \(error.localizedDescription)")
                        }
                    } else {
                        self.logger.warning("Transaction restored, but no receipt data available")
                        completion(false, "Transaction restored, but no receipt data available")
                    }
                case .deferred:
                    self.logger.warning("Transaction deferred")
                    completion(false, "Payment deferred")
                case .purchasing:
                    self.logger.warning("Transaction in progress")
                    // Do nothing
                @unknown default:
                    self.logger.warning("Unknown transaction state")
                    // Do nothing
                }
            }
        }
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: NoctuaService.self)
    )
}
