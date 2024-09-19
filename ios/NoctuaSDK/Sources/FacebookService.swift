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
    let enableDebug: Bool?
    let advertiserIdCollectionEnabled: Bool?
    let autologEventsEnabled: Bool?
    let appId: String
    let clientToken: String
    let displayName: String
    let disableCustomEvent: Bool?
    let eventMap: [String:String]
}

class FacebookService {
    let config: FacebookServiceConfig
    
    init(config: FacebookServiceConfig) throws {
#if canImport(FBSDKCoreKit)
        logger.info("Facebook module detected")
        self.config = config
        
        if config.enableDebug ?? false {
            Settings.shared.enableLoggingBehavior(.appEvents)
        }
        
        Settings.shared.isAdvertiserIDCollectionEnabled = config.advertiserIdCollectionEnabled ?? false
        Settings.shared.isAutoLogAppEventsEnabled = config.advertiserIdCollectionEnabled ?? false
        Settings.shared.appID = config.appId
        Settings.shared.clientToken = config.clientToken
        Settings.shared.displayName = config.displayName
        ApplicationDelegate.shared.initializeSDK()
        AppEvents.shared.activateApp()
#else
        throw FacebookServiceError.facebookNotFound
#endif
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FBSDKCoreKit)
        let eventName = config.eventMap["AdRevenue"] ?? "ad_revenue"

        var parameters: [AppEvents.ParameterName: Any] = [
            AppEvents.ParameterName("source"): source,
            AppEvents.ParameterName("ad_revenue"): revenue,
            AppEvents.ParameterName.currency: currency
        ]
        
        for (key, value) in extraPayload {
            parameters[AppEvents.ParameterName(key)] = value
        }

        AppEvents.shared.logEvent(AppEvents.Name(eventName), parameters: parameters)

        logger.debug("'\(eventName)' tracked: source: \(source), revenue: \(revenue), currency: \(currency), extraPayload: \(extraPayload)")
#endif
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FBSDKCoreKit)
        var parameters: [AppEvents.ParameterName: Any] = [
            AppEvents.ParameterName.orderID: orderId,
        ]
        
        for (key, value) in extraPayload {
            parameters[AppEvents.ParameterName(key)] = value
        }

        AppEvents.shared.logPurchase(amount: amount, currency: currency, parameters: parameters)
        
        logger.debug("Purchase tracked: currency: \(currency), amount: \(amount), orderId: \(orderId), extraPayload: \(extraPayload)")
#endif
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Any]) {
#if canImport(FBSDKCoreKit)
        if (config.disableCustomEvent ?? false) {
            return
        }
        
        let eventName = config.eventMap[eventName] ?? ""
        guard !eventName.isEmpty else  {
            logger.error("'\(eventName)' is not available in the eventMap")
            return
        }
        
        var parameters:[AppEvents.ParameterName: Any] = [:]
        for (key, value) in payload {
            parameters[AppEvents.ParameterName(key)] = value
        }

        AppEvents.shared.logEvent(AppEvents.Name(eventName), parameters: parameters)
        
        logger.debug("'\(eventName)' (custom) tracked: \(payload)")
#endif
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: FacebookService.self)
    )
}
