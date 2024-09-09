import Foundation
import os
import StoreKit

public typealias PurchaseCompletion = (Bool, String) -> Void

struct NoctuaServiceConfig : Decodable {
    let trackerURL: String?
}

class NoctuaService: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    let trackerURL: URL

    // Dictionary to store completion handlers for each product
    private var purchaseCompletions: [String: PurchaseCompletion] = [:]
    
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
        sendEvent(eventName, payload: payload)

    }

    func purchaseItem(productId: String, completion: @escaping PurchaseCompletion) {
        print("NativeSDK: NoctuaService - purchaseItem called with productId: \(productId)")
        initiatePayment(productId: "noctua.sdktest.ios.pack1", completion: { (success, message) in
            print("NativeSDK: NoctuaService - purchaseItem: \(success), \(message)")
            completion(success, message)
        })
    }
    
    private func sendEvent(_ eventName: String, payload: [String:Any]) {
        var payload = payload
        payload["event_name"] = eventName

        let bodyData = try? JSONEncoder().encode(payload.mapValues { AnyEncodable($0 as! Encodable) })
        
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
                self.logger.error("send event \(eventName) failed")
                return
            }
            
            if response == nil {
                self.logger.warning("send event finished with no response")
            }
            
            self.logger.debug("send event \(eventName) to \(response!.url!.absoluteString) succeeded")
        }

        task.resume()
    }

    private func initiatePayment(productId: String, completion: @escaping PurchaseCompletion) {
        purchaseCompletions[productId] = completion
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers: Set([productId]))
            request.delegate = self
            request.start()
        } else {
            // Handle the case where the user can't make payments
            print("User can't make payments")
            completion(false, "User can't make payments")
        }
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("productsRequest: \(response.products)")
        if let product = response.products.first {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            print("Product not found")
            if let productId = response.invalidProductIdentifiers.first,
               let completion = purchaseCompletions.removeValue(forKey: productId) {
                completion(false, "Product not found")
            }
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let productId = transaction.payment.productIdentifier
            guard let completion = purchaseCompletions[productId] else {
                continue
            }
            if let error = transaction.error as? SKError {
                switch error.code {
                case .paymentCancelled:
                    print("Payment cancelled")
                    completion(false, "cancelled")
                case .paymentInvalid:
                    print("Payment invalid")
                    completion(false, "invalid")
                case .paymentNotAllowed:
                    print("Payment not allowed")
                    completion(false, "not_allowed")
                default:
                    print("Other payment error: \(error.localizedDescription)")
                    completion(false, "error: \(error.localizedDescription)")
                }
            } else if let error = transaction.error as NSError? {
                if error.domain == "ASDErrorDomain" && error.code == 907 {
                    if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError,
                       underlyingError.domain == "AMSErrorDomain" && underlyingError.code == 6 {
                        print("Payment sheet cancelled")
                        completion(false, "cancelled")
                    } else {
                        print("ASDErrorDomain error: \(error.localizedDescription)")
                        completion(false, "error: \(error.localizedDescription)")
                    }
                } else {
                    print("Other error: \(error.localizedDescription)")
                    completion(false, "error: \(error.localizedDescription)")
                }
            } else {
                switch transaction.transactionState {
                case .purchased:
                    print("Transaction successful")
                    SKPaymentQueue.default().finishTransaction(transaction)
                    completion(true, "success")
                case .failed:
                    print("Transaction failed: \(String(describing: transaction.error?.localizedDescription))")
                    SKPaymentQueue.default().finishTransaction(transaction)
                    completion(false, "failed: \(String(describing: transaction.error?.localizedDescription))")
                case .restored:
                    print("Transaction restored")
                    SKPaymentQueue.default().finishTransaction(transaction)
                    completion(true, "restored")
                case .deferred:
                    print("Transaction deferred")
                    completion(false, "deferred")
                case .purchasing:
                    print("Transaction in progress")
                    // Do nothing
                @unknown default:
                    print("Unknown transaction state")
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
    let value: Encodable

    init(_ value: Encodable) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}


