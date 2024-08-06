import Foundation
import os

struct NoctuaConfig : Decodable {
    let productCode: String
    let noctua: NoctuaServiceConfig?
    let adjust: AdjustServiceConfig?
}

class NoctuaPlugin {
    let config: NoctuaConfig
    let noctua: NoctuaService?
    let adjust: AdjustService?
    
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
        }
        
        if self.config.adjust == nil {
            logger.warning("config for AdjustService not found")
            
            self.adjust = nil
        }
        else {
            do {
                self.adjust = try AdjustService(config: self.config.adjust!)
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
    }
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
        self.adjust?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
        self.noctua?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Any]) {
        self.adjust?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
        self.noctua?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Any]) {
        self.adjust?.trackCustomEvent(eventName, payload: payload)
        self.noctua?.trackCustomEvent(eventName, payload: payload)
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: NoctuaPlugin.self)
    )
}
