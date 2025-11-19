import Foundation
#if canImport(AdjustSdk)
import AdjustSdk
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
    let eventMap: [String:String]?
}

class AdjustService {
    let config: AdjustServiceIosConfig
    
    init(config: AdjustServiceIosConfig) throws {
#if canImport(AdjustSdk)
        self.config = config
        
        guard let eventMap = config.eventMap, !eventMap.isEmpty else {
            throw AdjustServiceError.invalidConfig("eventMap is empty")
        }

        guard eventMap.keys.contains("purchase") else {
            throw AdjustServiceError.invalidConfig("no eventToken for purchase")
        }
        
        let environment = config.environment?.isEmpty ?? true ? "sandbox" : config.environment!

        let appToken = config.appToken
        guard !appToken.isEmpty else {
            throw AdjustServiceError.invalidConfig("appToken is empty")
        }
        let adjustConfig = ADJConfig(appToken: appToken, environment: environment)
        adjustConfig?.logLevel = if config.environment == "production" { ADJLogLevel.warn } else { ADJLogLevel.debug }
        
        Adjust.initSdk(adjustConfig)
#else
        throw AdjustServiceError.adjustNotFound
#endif
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(AdjustSdk)
        let adRevenue = ADJAdRevenue(source: source)!
        adRevenue.setRevenue(revenue, currency: currency)
        
        for (key, value) in extraPayload {
            adRevenue.addCallbackParameter(key, value: "\(value)")
        }
        
        Adjust.trackAdRevenue(adRevenue)
#endif
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Any]) {
#if canImport(AdjustSdk)
        let eventToken = config.eventMap?["purchase"] ?? ""
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
#if canImport(AdjustSdk)
        if (config.customEventDisabled ?? false) {
            logger.warning("custom event is disabled")
            return
        }

        // Check for null
        guard let eventToken = config.eventMap?[eventName] else {
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

    func trackCustomEventWithRevenue(_ eventName: String, revenue: Double, currency: String, payload: [String:Any]) {
#if canImport(AdjustSdk)
        if (config.customEventDisabled ?? false) {
            logger.warning("custom event is disabled")
            return
        }
        
        // Check for null
        guard let eventToken = config.eventMap?[eventName] else {
            logger.warning("no eventToken for \(eventName)")
            return
        }

        // Check for empty string
        guard !eventToken.isEmpty else {
            logger.warning("no eventToken for \(eventName)")
            return
        }
        
        let event = ADJEvent(eventToken: eventToken)!
        
        var extraPayload = payload
        extraPayload["revenue"] = revenue
        extraPayload["currency"] = currency

        // Add parameters to the event`
        for (key, value) in extraPayload {
            event.addCallbackParameter(key, value: "\(value)")
        }
        
        Adjust.trackEvent(event)
#endif

    }

    func onOnline() {
#if canImport(AdjustSdk)
        Adjust.switchBackToOnlineMode()
#endif
    }

    func onOffline() {
#if canImport(AdjustSdk)
        Adjust.switchToOfflineMode()
        
#endif
    }   

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AdjustService.self)
    )
}
