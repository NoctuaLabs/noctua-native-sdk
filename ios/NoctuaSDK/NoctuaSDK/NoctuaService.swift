//
//  NoctuaService.swift
//  NoctuaSDK
//
//  Created by SDK Dev on 31/07/24.
//

import Foundation

struct NoctuaServiceConfig : Decodable {
    let trackerURL: String?
}

class NoctuaService {
    let trackerURL: String
    
    init(config: NoctuaServiceConfig) {
        trackerURL = if config.trackerURL == nil || config.trackerURL!.isEmpty {
            "https://kafka-proxy-poc.noctuaprojects.com/api/v1/events"
        } else {
            config.trackerURL!
        }
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Encodable]) {
        var payload = extraPayload
        payload["source"] = source
        payload["revenue"] = revenue
        payload["currency"] = currency
        payload["event_name"] = "AdRevenue"
        
        sendEvent(payload: payload)
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Encodable]) {
        var payload = extraPayload
        payload["orderId"] = orderId
        payload["amount"] = amount
        payload["currency"] = currency
        payload["event_name"] = "Purchase"
        
        sendEvent(payload: payload)
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Encodable]) {
        var payload = payload
        payload["event_name"] = eventName

        sendEvent(payload: payload)
    }
    
    private func sendEvent(payload: [String:Encodable]) {
        let encoder = JSONEncoder()
        let bodyData = encodeDictionaryToJSON(dictionary: payload)
        
        
        var request = URLRequest(url: URL(string: trackerURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data else { return }
        }

        task.resume()
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

    // Function to encode a dictionary of type [String: Encodable] to JSON
    private func encodeDictionaryToJSON(dictionary: [String: Encodable]) -> Data? {
        let encodableDictionary = dictionary.mapValues { AnyEncodable($0) }
        do {
            let jsonData = try JSONEncoder().encode(encodableDictionary)
            return jsonData
        } catch {
            print("Error encoding to JSON: \(error)")
            return nil
        }
    }
}
