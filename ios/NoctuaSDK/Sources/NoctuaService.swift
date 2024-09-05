import Foundation
import os
import StoreKit

struct NoctuaServiceConfig : Decodable {
    let trackerURL: String?
}

class NoctuaService: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    let trackerURL: URL
    
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

    func purchaseItem(productId: String) {
        initiatePayment(productId: "noctua.sdktest.ios.pack1")
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

    func initiatePayment(productId: String) {
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers: Set([productId]))
            request.delegate = self
            request.start()
        } else {
            // Handle the case where the user can't make payments
            print("User can't make payments")
        }
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("productsRequest: \(response.products)")
        if let product = response.products.first {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            print("Product not found")
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("------------------------------------------------------------")
        print("paymentQueue: \(transactions)")
        for transaction in transactions {
            if let error = transaction.error as? SKError {
                switch error.code {
                case .paymentCancelled:
                    print("Payment cancelled 1")
                case .paymentInvalid:
                    print("Payment invalid 2")
                case .paymentNotAllowed:
                    print("Payment not allowed 3")
                default:
                    print("Other payment error: \(error.localizedDescription)")
                }
            } else if let error = transaction.error as NSError? {
                if error.domain == "ASDErrorDomain" && error.code == 907 {
                    if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError,
                       underlyingError.domain == "AMSErrorDomain" && underlyingError.code == 6 {
                        print("Payment sheet cancelled 4")
                    } else {
                        print("ASDErrorDomain error: \(error.localizedDescription)")
                    }
                } else {
                    print("Other error: \(error.localizedDescription)")
                }
            } else {
                print("Unknown error")
            }
            switch transaction.transactionState {
            case .purchased:
                print("Transaction successful")
                SKPaymentQueue.default().finishTransaction(transaction)
                // Handle successful purchase
            case .failed:
                print("Transaction failed: \(String(describing: transaction.error?.localizedDescription))")
                SKPaymentQueue.default().finishTransaction(transaction)
                // Handle failed purchase
            case .restored:
                print("Transaction restored")
                SKPaymentQueue.default().finishTransaction(transaction)
                // Handle restored purchase
            case .deferred:
                print("Transaction deferred")
            case .purchasing:
                print("Transaction in progress")
            @unknown default:
                print("Unknown transaction state")
            }
        }
    }

    // Call this method when initializing your NoctuaService
    func setupPayments() {
        SKPaymentQueue.default().add(self)
    }

    // Call this method when your app is being terminated
    func tearDownPayments() {
        SKPaymentQueue.default().remove(self)
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


