//
//  FirebaseService.swift
//  NoctuaSDK
//
//  Created by Noctua Eng 2 on 05/08/24.
//

import Foundation
#if canImport(FirebaseAnalytics)
import FirebaseCore
import FirebaseAnalytics
#endif
import os

enum FirebaseServiceError : Error {
    case firebaseNotFound
    case invalidConfig(String)
}

struct FirebaseServiceConfig : Codable {
    let disableCustomEvent: Bool?
    let eventMap: [String:String]
}

class FirebaseService {
    let config: FirebaseServiceConfig
    
    init(config: FirebaseServiceConfig) throws {
#if canImport(FirebaseAnalytics)
        logger.info("Firebase module detected")
        self.config = config
        
        guard !config.eventMap.isEmpty else {
            throw FirebaseServiceError.invalidConfig("eventMap is empty")
        }
        
        guard config.eventMap.keys.contains("Purchase") else {
            throw FirebaseServiceError.invalidConfig("no eventToken for purchase")
        }
        
        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(true)
        
#else
        throw FirebaseServiceError.firebaseNotFound
#endif
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FirebaseAnalytics)
        let eventName = config.eventMap["AdRevenue"] ?? "ad_revenue"

        var parameters: [String:Any] = [
            AnalyticsParameterAdSource: source,
            AnalyticsParameterValue: revenue,
            AnalyticsParameterCurrency: currency
        ]
        
        for (key, value) in extraPayload {
            parameters[key] = value
        }

        Analytics.logEvent(eventName, parameters: parameters)

        logger.debug("'\(eventName)' tracked: source: \(source), revenue: \(revenue), currency: \(currency), extraPayload: \(extraPayload)")
#endif
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FirebaseAnalytics)
        var parameters: [String: Any] = [
            AnalyticsParameterTransactionID: orderId,
            AnalyticsParameterValue: amount,
            AnalyticsParameterCurrency: currency
        ]
        
        for (key, value) in extraPayload {
            parameters[key] = value
        }

        Analytics.logEvent(AnalyticsEventPurchase, parameters: parameters)

        logger.debug("'\(AnalyticsEventPurchase)' tracked: currency: \(currency), amount: \(amount), orderId: \(orderId), extraPayload: \(extraPayload)")
#endif
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Any]) {
#if canImport(FirebaseAnalytics)
        if (config.disableCustomEvent ?? false) {
            return
        }
        
        let eventName = config.eventMap[eventName] ?? ""
        guard !eventName.isEmpty else  {
            logger.error("'\(eventName)' (custom) is not available in the eventMap")
            return
        }
       
        Analytics.logEvent(eventName, parameters: payload)

        logger.debug("'\(eventName)' (custom) tracked: payload: \(payload)")
#endif
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: FirebaseService.self)
    )
}
