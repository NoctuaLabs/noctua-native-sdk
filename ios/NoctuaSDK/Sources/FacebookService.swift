//
//  FacebookService.swift
//  NoctuaSDK
//
//  Created by Noctua Eng 2 on 05/08/24.
//

import Foundation
#if canImport(FBAEMKit)
import FBSDKCoreKit
import FBAEMKit
#endif
import os

enum FacebookServiceError : Error {
    case facebookNotFound
    case invalidConfig(String)
}

struct FacebookServiceConfig : Codable {
    let environment: String?
    let eventMap: [String:String]
}

class FacebookService {
    let config: FacebookServiceConfig
    
    init(config: FacebookServiceConfig) throws {
#if canImport(FBAEMKit)
        logger.info("Facebook module detected")
        self.config = config
        
        guard !config.eventMap.isEmpty else {
            throw FacebookServiceError.invalidConfig("eventMap is empty")
        }
        
        guard config.eventMap.keys.contains("Purchase") else {
            throw FacebookServiceError.invalidConfig("no eventToken for purchase")
        }
        
        let environment = if config.environment == nil || config.environment!.isEmpty { "sandbox" } else { config.environment! }
        
        // No init func from the Facebook AEM kit
#else
        throw FacebookServiceError.facebookNotFound
#endif
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Encodable]) {
#if canImport(FBAEMKit)
        let facebookEventName = config.eventMap["AdRevenue"] ?? ""
        guard !facebookEventName.isEmpty else  {
            print("Event name for AdRevenue is not registered in the eventMap")
            return
        }

        var parameters: [AppEvents.ParameterName: Any] = [
            AppEvents.ParameterName("source"): source,
            AppEvents.ParameterName("ad_revenue"): revenue,
            AppEvents.ParameterName("currency"): currency
        ]
        
        for (key, value) in extraPayload {
            parameters[AppEvents.ParameterName(key)] = value
        }

        AppEvents.shared.logEvent(AppEvents.Name(facebookEventName), parameters: parameters)
#endif
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Encodable]) {
#if canImport(FBAEMKit)
        let facebookEventName = config.eventMap["Purchase"] ?? ""
        guard !facebookEventName.isEmpty else  {
            print("Event name for Purchase is not registered in the eventMap")
            return
        }
                                                
        var parameters: [AppEvents.ParameterName: Any] = [
            AppEvents.ParameterName("order_id"): orderId,
            AppEvents.ParameterName("amount"): amount,
            AppEvents.ParameterName("currency"): currency
        ]
        
        for (key, value) in extraPayload {
            parameters[AppEvents.ParameterName(key)] = value
        }
        AppEvents.shared.logEvent(AppEvents.Name(facebookEventName), parameters: parameters)
#endif
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Encodable]) {
#if canImport(FBAEMKit)
        let facebookEventName = config.eventMap[eventName] ?? ""
        guard !facebookEventName.isEmpty else  {
            print("Event name for " + eventName + " is not registered in the eventMap")
            return
        }
        
        var parameters:[AppEvents.ParameterName: Any] = [:]
        for (key, value) in payload {
            parameters[AppEvents.ParameterName(key)] = value
        }
        AppEvents.shared.logEvent(AppEvents.Name(facebookEventName), parameters: parameters)
#endif
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: NoctuaPlugin.self)
    )
}
