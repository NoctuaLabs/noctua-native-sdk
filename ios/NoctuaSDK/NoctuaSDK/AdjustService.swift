//
//  AdjustService.swift
//  NoctuaSDK
//
//  Created by SDK Dev on 31/07/24.
//

import Foundation
#if canImport(Adjust)
import Adjust
#endif

enum AdjustServiceError : Error {
    case adjustNotFound
}

struct AdjustServiceConfig : Codable {
    let appToken: String
    let environment: String?
    let eventMap: [String:String]
}

class AdjustService {
    let config: AdjustServiceConfig
    
    init(config: AdjustServiceConfig) throws {
        self.config = config
        
        guard !config.eventMap.isEmpty else {
            throw ConfigurationError.missingKey("eventMap is empty")
        }
        
        guard !config.eventMap.keys.contains("Purchase") else {
            throw ConfigurationError.missingKey("no eventToken for purchase")
        }
        
        let environment = if config.environment == nil || config.environment!.isEmpty { "sandbox" } else { config.environment! }

#if canImport(Adjust)
        let adjustConfig = ADJConfig(appToken: config.appToken, environment: environment)
        adjustConfig?.logLevel = if config.environment == "production" { ADJLogLevelWarn } else { ADJLogLevelDebug }
        
        Adjust.appDidLaunch(adjustConfig)
#else
        throw AdjustServiceError.adjustNotFound
#endif
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Encodable]) {
#if canImport(Adjust)
        let adRevenue = ADJAdRevenue(source: source)!
        adRevenue.setRevenue(revenue, currency: currency)
        
        for (key, value) in extraPayload {
            adRevenue.addCallbackParameter(key, value: "\(value)")
        }
        
        Adjust.trackAdRevenue(adRevenue)
#endif
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Encodable]) {
#if canImport(Adjust)
        let purchase = ADJEvent(eventToken: config.eventMap["Purchase"]!)!
        purchase.setTransactionId(orderId)
        purchase.setRevenue(amount, currency: currency)
        
        for (key, value) in extraPayload {
            purchase.addCallbackParameter(key, value: "\(value)")
        }

        Adjust.trackEvent(purchase)
#endif
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Encodable]) {
#if canImport(Adjust)
        let event = ADJEvent(eventToken: config.eventMap[eventName]!)!

        for (key, value) in payload {
            event.addCallbackParameter(key, value: "\(value)")
        }

        Adjust.trackEvent(event)
#endif
    }
}
