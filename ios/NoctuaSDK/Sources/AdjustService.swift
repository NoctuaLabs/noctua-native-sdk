import Foundation
#if canImport(Adjust)
import Adjust
#endif
import os

enum AdjustServiceError : Error {
    case adjustNotFound
    case invalidConfig(String)
}

struct AdjustServiceConfig : Codable {
    let ios: AdjustServiceIosConfig?
}

struct AdjustServiceIosConfig : Codable {
    let appToken: String
    let environment: String?
    let customEventDisabled: Bool?
    let eventMap: [String:String]
}

class AdjustService {
    let config: AdjustServiceIosConfig
    
    init(config: AdjustServiceIosConfig) throws {
#if canImport(Adjust)
        self.config = config
        
        guard !config.eventMap.isEmpty else {
            throw AdjustServiceError.invalidConfig("eventMap is empty")
        }
        
        guard config.eventMap.keys.contains("purchase") else {
            throw AdjustServiceError.invalidConfig("no eventToken for purchase")
        }
        
        let environment = config.environment?.isEmpty ?? true ? "sandbox" : config.environment!

        let appToken = config.appToken
        guard !appToken.isEmpty else {
            throw AdjustServiceError.invalidConfig("appToken is empty")
        }
        let adjustConfig = ADJConfig(appToken: appToken, environment: environment)
        adjustConfig?.logLevel = if config.environment == "production" { ADJLogLevelWarn } else { ADJLogLevelDebug }
        
        Adjust.appDidLaunch(adjustConfig)
#else
        throw AdjustServiceError.adjustNotFound
#endif
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(Adjust)
        let adRevenue = ADJAdRevenue(source: source)!
        adRevenue.setRevenue(revenue, currency: currency)
        
        for (key, value) in extraPayload {
            adRevenue.addCallbackParameter(key, value: "\(value)")
        }
        
        Adjust.trackAdRevenue(adRevenue)
#endif
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(Adjust)
        let eventToken = config.eventMap["purchase"]!
        guard !eventToken.isEmpty else {
            logger.warning("no eventToken for purchase")
            return
        }
        let purchase = ADJEvent(eventToken: eventToken)!
        purchase.setTransactionId(orderId)
        purchase.setRevenue(amount, currency: currency)
        
        for (key, value) in extraPayload {
            purchase.addCallbackParameter(key, value: "\(value)")
        }

        Adjust.trackEvent(purchase)
#endif
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Any]) {
#if canImport(Adjust)
        if (config.customEventDisabled ?? false) {
            logger.warning("custom event is disabled")
            return
        }

        // Check for null
        guard let eventToken = config.eventMap[eventName] else {
            logger.warning("no eventToken for \(eventName)")
            return
        }

        // Check for empty string
        guard !eventToken.isEmpty else {
            logger.warning("no eventToken for \(eventName)")
            return
        }

        let event = ADJEvent(eventToken: eventToken)!

        for (key, value) in payload {
            event.addCallbackParameter(key, value: "\(value)")
        }

        Adjust.trackEvent(event)
#endif
    }

    func onOnline() {
#if canImport(Adjust)
        Adjust.setOfflineMode(false)
#endif
    }

    func onOffline() {
#if canImport(Adjust)
        Adjust.setOfflineMode(true)
#endif
    }   

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AdjustService.self)
    )
}
