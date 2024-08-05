import Foundation
import os

struct NoctuaConfig : Decodable {
    let productCode: String
    let noctua: NoctuaServiceConfig?
    let adjust: AdjustServiceConfig?
    let firebase: FirebaseServiceConfig?
    let facebook: FacebookServiceConfig?
}

class NoctuaPlugin {
    let config: NoctuaConfig
    let noctua: NoctuaService?
    let adjust: AdjustService?
    let firebase: FirebaseService?
    let facebook: FacebookService?

    init(config: NoctuaConfig) {
        self.config = config
        

        if self.config.noctua == nil {
            logger.warning("config for NoctuaService not found")

            self.noctua = nil
        }
        else {
            self.noctua = try? NoctuaService(config: self.config.noctua!)

            if self.noctua == nil {
                logger.warning("NoctuaService disabled due to initialization error")
            }
            logger.info("NoctuaService initialized")
        }
        
        if self.config.adjust == nil {
            logger.warning("config for AdjustService not found")
            
            self.adjust = nil
        }
        else {
            do {
                self.adjust = try AdjustService(config: self.config.adjust!)
                logger.info("AdjustService initialized")
            }
            catch AdjustServiceError.adjustNotFound {
                logger.warning("Adjust disabled, Adjust module not found")
                
                self.adjust = nil
            }
            catch AdjustServiceError.invalidConfig(let message) {
                logger.warning("Adjust disabled, invalid Adjust config: \(message)")
                
                self.adjust = nil
            }
            catch {
                logger.warning("Adjust disabled, unknown error")

                self.adjust = nil
            }
        }
        
        if self.config.firebase == nil {
            logger.warning("config for FirebaseService not found")
            
            self.firebase = nil
        }
        else {
            do {
                self.firebase = try FirebaseService(config: self.config.firebase!)
                logger.info("FirebaseService initialized")
            }
            catch FirebaseServiceError.firebaseNotFound {
                logger.warning("Firebase disabled, Firebase module not found")
                
                self.firebase = nil
            }
            catch FirebaseServiceError.invalidConfig(let message) {
                logger.warning("Firebase disabled, invalid Firebase config: \(message)")
                
                self.firebase = nil
            }
            catch {
                logger.warning("Firebase disabled, unknown error")

                self.firebase = nil
            }
        }
        
        if self.config.facebook == nil {
            logger.warning("config for FacebookService not found")
            
            self.facebook = nil
        }
        else {
            do {
                self.facebook = try FacebookService(config: self.config.facebook!)
                logger.info("FacebookService initialized")
            }
            catch FacebookServiceError.facebookNotFound {
                logger.warning("Facebook disabled, Facebook module not found")

                self.facebook = nil
            }
            catch FacebookServiceError.invalidConfig(let message) {
                logger.warning("Facebook disabled, invalid Facebook config: \(message)")

                self.facebook = nil
            }
            catch {
                logger.warning("Facebook disabled, unknown error")

                self.facebook = nil
            }
        }
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Encodable]) {
        self.adjust?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
        self.noctua?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
        self.firebase?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Encodable]) {
        self.adjust?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
        self.noctua?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
        self.firebase?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Encodable]) {
        self.adjust?.trackCustomEvent(eventName, payload: payload)
        self.noctua?.trackCustomEvent(eventName, payload: payload)
        self.firebase?.trackCustomEvent(eventName, payload: payload)
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: NoctuaPlugin.self)
    )
}
