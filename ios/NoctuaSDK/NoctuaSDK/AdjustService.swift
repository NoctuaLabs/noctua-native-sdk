//
//  AdjustService.swift
//  NoctuaSDK
//
//  Created by SDK Dev on 31/07/24.
//

import Foundation

import Adjust

struct AdjustServiceConfig : Codable {
    let appToken: String
    let environment: String?
    let eventMap: [String:String]
}

class AdjustService {
    let config: AdjustServiceConfig
    
    init(config: AdjustServiceConfig) {
        self.config = config
        
        let adjustConfig = ADJConfig(appToken: config.appToken, environment: config.environment ?? "sandbox")
        adjustConfig?.logLevel = if config.environment == "production" { ADJLogLevelWarn } else { ADJLogLevelDebug }
        
        Adjust.appDidLaunch(adjustConfig)
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Encodable]) {
        var adRevenue = ADJAdRevenue(source: source)!
        adRevenue.setRevenue(revenue, currency: currency)
        
        for (key, value) in extraPayload {
            adRevenue.setValue(value, forKey: key)
        }
        
        Adjust.trackAdRevenue(adRevenue)
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Encodable]) {
        var purchase = ADJEvent(eventToken: config.eventMap["Purchase"]!)!
        purchase.setTransactionId(orderId)
        purchase.setRevenue(amount, currency: currency)
        
        for (key, value) in extraPayload {
            purchase.setValue(value, forKey: key)
        }

        Adjust.trackEvent(purchase)
    }
    
    func trackCustomEvent(eventName: String, payload: [String:Any]) {
        var event = ADJEvent(eventToken: config.eventMap[eventName]!)!

        for (key, value) in payload {
            event.setValue(value, forKey: key)
        }

        Adjust.trackEvent(event)
    }
}
