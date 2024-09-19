import Foundation
import os
import StoreKit

public typealias CompletionCallback = (Bool, String) -> Void

struct NoctuaServiceConfig : Decodable {
    let trackerURL: String?
    let disableCustomEvent: Bool?
    let disableTracker: Bool?
}

class NoctuaService: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    let trackerURL: URL
    let disableCustomEvent: Bool
    let disableTracker: Bool

    // Used to differentiate between different StoreKit operation
    private var storeKitOperation: String? = nil
    // One StoreKit operation at a time
    private var completionHandler: CompletionCallback? = nil

    init(config: NoctuaServiceConfig) throws {
        let url = if config.trackerURL == nil || config.trackerURL!.isEmpty {
            URL(string:"https://kafka-proxy-poc.noctuaprojects.com/api/v1/events")
        } else {
            URL(string: config.trackerURL!)
        }
        
        guard url != nil else {
            throw InitError.invalidArgument(config.trackerURL!)
        }
        
        trackerURL = url!
        disableCustomEvent = config.disableCustomEvent ?? false
        disableTracker = config.disableTracker ?? false

        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
        var payload = extraPayload
        payload["source"] = source
        payload["revenue"] = revenue
        payload["currency"] = currency

        sendEvent("AdRevenue", payload: payload)
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Any]) {
        var payload = extraPayload
        payload["orderId"] = orderId
        payload["amount"] = amount
        payload["currency"] = currency
        
        sendEvent("Purchase", payload: payload)
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Any]) {
        if (disableCustomEvent) {
            return
        }
        
        sendEvent(eventName, payload: payload)
    }

    func getActiveCurrency(productId: String, completion: @escaping CompletionCallback) {
        completionHandler = completion
        storeKitOperation = "getActiveCurrency"
        let request = SKProductsRequest(productIdentifiers: Set([productId]))
        request.delegate = self
        request.start() // continue to productsRequest
    }

    func purchaseItem(productId: String, completion: @escaping CompletionCallback) {
        completionHandler = completion
        storeKitOperation = "purchaseItem"
        self.logger.info("Noctua SDK Native: NoctuaService.purchaseItem called with productId: \(productId)")
        initiatePayment(productId: productId, completion: { (success, message) in
            self.logger.info("purchaseItem: \(success), \(message)")
            completion(success, message)
        })
    }
    
    private func sendEvent(_ eventName: String, payload: [String:Any]) {
        if (disableTracker) {
            return
        }
        
        var payload = payload
        payload["event_name"] = eventName

        let bodyData = try? JSONEncoder().encode(payload.mapValues { AnyEncodable($0) })
        
        guard bodyData != nil else {
            self.logger.error("unable to encode event \(eventName) as json: \(payload)")
            return
        }
        
        var request = URLRequest(url: trackerURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let task = URLSession.shared.dataTask(with: request) { 
            (data, response, error) in
            
            guard error == nil else {
                self.logger.error("Sending event \(eventName) failed")
                return
            }
            
            if response == nil {
                self.logger.warning("Event \(eventName) sent with no response")
            }
            
            self.logger.debug("Event \(eventName) sent, payload: \(bodyData!)")
        }

        task.resume()
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
        let completion = completionHandler!
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

private struct AnyEncodable: Encodable {
    private let value: Encodable

    init(_ value: Any) {
        let cfValue = value as CFTypeRef
        let typeID = CFGetTypeID(cfValue)
        
        if typeID == CFBooleanGetTypeID() {
            self.value = (value as! Bool)
        } else if typeID == CFNumberGetTypeID() {
            let number = value as! NSNumber
            switch CFNumberGetType(number as CFNumber) {
            case .charType:
                self.value = number.boolValue
            case .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type, .intType, .shortType, .longType, .longLongType:
                self.value = number.intValue
            case .float32Type, .float64Type, .floatType, .doubleType, .cgFloatType:
                self.value = number.doubleValue
            default:
                self.value = number.stringValue
            }
        } else if let value = value as? NSString {
            self.value = value as String
        } else {
            self.value = "\(value)"
        }
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}


