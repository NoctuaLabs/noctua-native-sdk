import Foundation
#if canImport(Adjust)
import Adjust
#endif

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
    let disableCustomEvent: Bool?
    let eventMap: [String:String]
}

class AdjustService {
    let config: AdjustServiceConfig
    
    init(config: AdjustServiceConfig) throws {
#if canImport(Adjust)
        self.config = config
        
        guard ((config.ios?.eventMap.isEmpty) == nil) else {
            throw AdjustServiceError.invalidConfig("eventMap is empty")
        }
        
        guard ((config.ios?.eventMap.keys.contains("Purchase")) != nil) else {
            throw AdjustServiceError.invalidConfig("no eventToken for purchase")
        }
        
        let environment = config.ios?.environment?.isEmpty == false
            ? config.ios!.environment!
            : "sandbox"

        let appToken = config.ios?.appToken ?? ""
        guard appToken.isEmpty == false else {
            throw AdjustServiceError.invalidConfig("appToken is empty")
        }
        let adjustConfig = ADJConfig(appToken: appToken, environment: environment)
        adjustConfig?.logLevel = if config.ios?.environment == "production" { ADJLogLevelWarn } else { ADJLogLevelDebug }
        
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
        let eventToken = config.ios?.eventMap["Purchase"]! ?? ""
        guard eventToken.isEmpty == false else {
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
        if (config.ios?.disableCustomEvent ?? false) {
            return
        }
        let eventToken = config.ios?.eventMap[eventName]! ?? ""
        guard eventToken.isEmpty == false else {
            return
        }
        let event = ADJEvent(eventToken: eventToken)!

        for (key, value) in payload {
            event.addCallbackParameter(key, value: "\(value)")
        }

        Adjust.trackEvent(event)
#endif
    }
}
