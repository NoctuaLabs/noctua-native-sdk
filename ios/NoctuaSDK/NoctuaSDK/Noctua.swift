//
//  Noctua.swift
//  NoctuaSDK
//
//  Created by SDK Dev on 31/07/24.
//

import Foundation

struct NoctuaConfig : Decodable {
    let productCode: String
    let noctua: NoctuaServiceConfig?
    let adjust: AdjustServiceConfig?
}

class Noctua {
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
        
        self.adjust = if (self.config.adjust != nil) {
            AdjustService(config: self.config.adjust!)
        } else {
            nil
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
        self.adjust?.trackCustomEvent(eventName: eventName, payload: payload)
        self.noctua?.trackCustomEvent(eventName, payload: payload)
    }
}
