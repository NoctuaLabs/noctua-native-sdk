//
//  NoctuaPlugin.swift
//  NoctuaSDK
//
//  Created by SDK Dev on 01/08/24.
//

import Foundation

struct NoctuaConfig : Decodable {
    let productCode: String
    let noctua: NoctuaServiceConfig?
    let adjust: AdjustServiceConfig?
}

class NoctuaPlugin {
    let config: NoctuaConfig
    let noctua: NoctuaService?
    let adjust: AdjustService?
    
    init(config: NoctuaConfig) {
        self.config = config
        
        self.noctua = if (self.config.noctua != nil) {
            NoctuaService(config: self.config.noctua!)
        } else {
            nil
        }
        
        if self.config.adjust == nil {
            self.adjust = nil
        }
        else {
            self.adjust = try? AdjustService(config: self.config.adjust!)
        }
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Encodable]) {
        self.adjust?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
        self.noctua?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Encodable]) {
        self.adjust?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
        self.noctua?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Encodable]) {
        self.adjust?.trackCustomEvent(eventName, payload: payload)
        self.noctua?.trackCustomEvent(eventName, payload: payload)
    }
}

enum ConfigurationError: Error {
    case fileNotFound
    case invalidFormat
    case missingKey(String)
    case unknown(Error)
}

func loadConfig() throws -> NoctuaConfig {
    guard let path = Bundle.main.path(forResource: "noctuagg", ofType: "json") else {
        throw ConfigurationError.fileNotFound
    }
    
    let config: NoctuaConfig
    
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        config = try JSONDecoder().decode(NoctuaConfig.self, from: data)
    } catch {
        throw ConfigurationError.invalidFormat
    }
    
    if config.productCode.isEmpty {
        throw ConfigurationError.missingKey("productCode")
    }
    
    return config
}
