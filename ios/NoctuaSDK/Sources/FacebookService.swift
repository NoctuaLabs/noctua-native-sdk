//
//  FacebookService.swift
//  NoctuaSDK
//
//  Created by Noctua Eng 2 on 05/08/24.
//

import Foundation
#if canImport(FBSDKCoreKit)
import FBSDKCoreKit
#endif
import os

enum FacebookServiceError : Error {
    case facebookNotFound
    case invalidConfig(String)
}

struct FacebookServiceConfig : Codable {
    let eventMap: [String:String]
}

class FacebookService {
    let config: FacebookServiceConfig
    
    init(config: FacebookServiceConfig) throws {
#if canImport(FBSDKCoreKit)
        logger.info("Facebook module detected")
        self.config = config
        
        guard !config.eventMap.isEmpty else {
            throw FacebookServiceError.invalidConfig("eventMap is empty")
        }
        
        guard config.eventMap.keys.contains("Purchase") else {
            throw FacebookServiceError.invalidConfig("no eventToken for purchase")
        }
        
        AppEvents.shared.activateApp()
#else
        throw FacebookServiceError.facebookNotFound
#endif
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FBSDKCoreKit)
        let facebookEventName = config.eventMap["AdRevenue"] ?? ""
        guard !facebookEventName.isEmpty else  {
            logger.warning("Event name for AdRevenue is not registered in the eventMap")
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
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FBSDKCoreKit)
        var parameters: [AppEvents.ParameterName: Any] = [
            AppEvents.ParameterName("fb_transaction_id"): orderId,
        ]
        
        for (key, value) in extraPayload {
            parameters[AppEvents.ParameterName(key)] = value
        }
        AppEvents.shared.logPurchase(amount: amount, currency: currency, parameters: parameters)
        logger.debug("Facebook Purchase, amount: \(amount), currency: \(currency), parameters: \(parameters)")
#endif
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Any]) {
#if canImport(FBSDKCoreKit)
        let facebookEventName = config.eventMap[eventName] ?? ""
        guard !facebookEventName.isEmpty else  {
            logger.warning("Event name for \(eventName) is not registered in the eventMap")
            return
        }
        
        var parameters:[AppEvents.ParameterName: Any] = [:]
        for (key, value) in payload {
            parameters[AppEvents.ParameterName(key)] = value
        }
        AppEvents.shared.logEvent(AppEvents.Name(facebookEventName), parameters: parameters)
        logger.debug("Facebook \(facebookEventName), parameters: \(parameters)")
#endif
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: FacebookService.self)
    )
}
