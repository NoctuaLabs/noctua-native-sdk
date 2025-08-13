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
    let ios: FirebaseServiceIosConfig?
}

struct FirebaseServiceIosConfig : Codable {
    let customEventDisabled: Bool?
}

class FirebaseService {
    let config: FirebaseServiceIosConfig
    
    init(config: FirebaseServiceIosConfig) throws {
#if canImport(FirebaseAnalytics)
        logger.info("Firebase module detected")
        self.config = config
        
        if (FirebaseApp.app() == nil)
        {
            FirebaseApp.configure()
        }

        Analytics.setAnalyticsCollectionEnabled(true)
        
#else
        throw FirebaseServiceError.firebaseNotFound
#endif
    }
    
    private func getAdplatform(from source: String) -> String {
        switch source {
        case "applovin_max_sdk":
            return "appLovin"
        case "admob_sdk":
            return "admob"
        case "unity_ads_sdk":
            return "unity"
        default:
            return "unknown"
        }
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FirebaseAnalytics)
        var parameters: [String:Any] = [
            AnalyticsParameterAdPlatform: getAdplatform(from: source),
            AnalyticsParameterAdSource: source,
            AnalyticsParameterValue: revenue,
            AnalyticsParameterCurrency: currency
        ]
        
        for (key, value) in extraPayload {
            parameters[key] = value
        }

        Analytics.logEvent("ad_revenue", parameters: parameters)
        Analytics.logEvent(AnalyticsEventAdImpression, parameters: parameters)

        logger.debug("'ad_revenue' tracked: source: \(source), revenue: \(revenue), currency: \(currency), extraPayload: \(extraPayload)")
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
        if (config.customEventDisabled ?? false) {
            return
        }
        
        let suffix = (payload["suffix"] as? CustomStringConvertible).flatMap { "\($0)".isEmpty ? nil : "_\($0)" } ?? ""
        let payload = payload.filter { $0.key != "suffix" }
        
        Analytics.logEvent("gf_\(eventName)\(suffix)", parameters: payload)

        logger.debug("'gf_\(eventName)\(suffix)' (custom) tracked: payload: \(payload)")
#endif
    }

    func trackCustomEventWithRevenue(_ eventName: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(FirebaseAnalytics)
        if (config.customEventDisabled ?? false) {
            return
        }
        
        var parameters: [String: Any] = [
            AnalyticsParameterValue: revenue,
            AnalyticsParameterCurrency: currency
        ]
        
        for (key, value) in extraPayload {
            parameters[key] = value
        }
        
        Analytics.logEvent("gf_\(eventName)", parameters: extraPayload)

        logger.debug("'gf_\(eventName)' (custom) tracked: payload: \(extraPayload)")
#endif
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: FirebaseService.self)
    )
}
