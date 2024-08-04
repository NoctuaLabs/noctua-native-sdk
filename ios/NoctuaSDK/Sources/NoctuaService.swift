import Foundation
import os

struct NoctuaServiceConfig : Decodable {
    let trackerURL: String?
}

class NoctuaService {
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
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Encodable]) {
        var payload = extraPayload
        payload["source"] = source
        payload["revenue"] = revenue
        payload["currency"] = currency
        
        sendEvent("AdRevenue", payload: payload)
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Encodable]) {
        var payload = extraPayload
        payload["orderId"] = orderId
        payload["amount"] = amount
        payload["currency"] = currency
        
        sendEvent("Purchase", payload: payload)
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Encodable]) {
        sendEvent(eventName, payload: payload)
    }
    
    private func sendEvent(_ eventName: String, payload: [String:Encodable]) {
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


