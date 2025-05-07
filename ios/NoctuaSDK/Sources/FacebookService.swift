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
    let ios: FacebookServiceIosConfig?
}

struct FacebookServiceIosConfig : Codable {
    let enableDebug: Bool?
    let advertiserIdCollectionEnabled: Bool?
    let autologEventsEnabled: Bool?
    let appId: String
    let clientToken: String
    let displayName: String
    let customEventDisabled: Bool?
}

class FacebookService {
    let config: FacebookServiceIosConfig
    
    init(config: FacebookServiceIosConfig) throws {
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
        var parameters: [AppEvents.ParameterName: Any] = [
            AppEvents.ParameterName("source"): source,
            AppEvents.ParameterName("ad_revenue"): revenue,
            AppEvents.ParameterName.currency: currency
        ]
        
        for (key, value) in extraPayload {
            parameters[AppEvents.ParameterName(key)] = value
        }

        AppEvents.shared.logEvent(AppEvents.Name("ad_revenue"), parameters: parameters)

        logger.debug("'ad_revenue' tracked: source: \(source), revenue: \(revenue), currency: \(currency), extraPayload: \(extraPayload)")
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
        if (config.customEventDisabled ?? false) {
            return
        }
        
        let suffix = (payload["suffix"] as? CustomStringConvertible).flatMap { "\($0)".isEmpty ? nil : "_\($0)" } ?? ""

        var parameters:[AppEvents.ParameterName: Any] = [:]
        for (key, value) in payload {
            if (key == "suffix") {
                continue
            }
            
            parameters[AppEvents.ParameterName(key)] = value
        }

        AppEvents.shared.logEvent(AppEvents.Name("fb_\(eventName)\(suffix)"), parameters: parameters)
        
        logger.debug("'fb_\(eventName)\(suffix)' (custom) tracked: \(parameters)")
#endif
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: FacebookService.self)
    )
}
