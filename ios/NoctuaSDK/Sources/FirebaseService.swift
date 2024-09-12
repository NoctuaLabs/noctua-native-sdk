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
        
        if (FirebaseApp.app() == nil) {
            FirebaseApp.configure()
        }
#else
        throw FirebaseServiceError.firebaseNotFound
#endif
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FirebaseAnalytics)
        let firebaseEventName = config.eventMap["AdRevenue"] ?? ""
        guard !firebaseEventName.isEmpty else  {
            print("Event name for AdRevenue is not registered in the eventMap")
            return
        }

        var parameters: [String:Any] = [
            "source": source,
            "ad_revenue": revenue,
            AnalyticsParameterCurrency: currency
        ]
        
        for (key, value) in extraPayload {
            parameters[key] = value
        }
        Analytics.logEvent(firebaseEventName, parameters: parameters)
#endif
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FirebaseAnalytics)
        let firebaseEventName = config.eventMap["Purchase"] ?? ""
        guard !firebaseEventName.isEmpty else  {
            print("Event name for Purchase is not registered in the eventMap")
            return
        }
                                                
        var parameters: [String: Any] = [
            AnalyticsParameterTransactionID: orderId,
            AnalyticsParameterValue: amount,
            AnalyticsParameterCurrency: currency
        ]
        
        for (key, value) in extraPayload {
            parameters[key] = value
        }
        Analytics.logEvent(firebaseEventName, parameters: parameters)
#endif
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Any]) {
#if canImport(FirebaseAnalytics)
        let firebaseEventName = config.eventMap[eventName] ?? ""
        guard !firebaseEventName.isEmpty else  {
            print("Event name for " + eventName + " is not registered in the eventMap")
            return
        }
       
        Analytics.logEvent(firebaseEventName, parameters: payload)
#endif
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: NoctuaPlugin.self)
    )
}
