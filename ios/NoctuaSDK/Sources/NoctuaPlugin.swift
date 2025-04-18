import Foundation
import os

struct NoctuaConfig : Decodable {
    let clientId: String
    let noctua: NoctuaServiceConfig?
    let adjust: AdjustServiceConfig?
    let firebase: FirebaseServiceConfig?
    let facebook: FacebookServiceConfig?
}

class NoctuaPlugin {
    private let config: NoctuaConfig
    private let accountRepo: AccountRepository
    private let noctua: NoctuaService?
    private let adjust: AdjustService?
    private let firebase: FirebaseService?
    private let facebook: FacebookService?

    init(config: NoctuaConfig) {
        self.config = config
        
        self.accountRepo = AccountRepository()

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
        } else if self.config.adjust?.ios == nil {
            logger.warning("config for AdjustService IOS not found")

            self.adjust = nil
        }
        else {
            do {
                self.adjust = try AdjustService(config: (self.config.adjust?.ios!)!)
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
        } else if self.config.firebase?.ios == nil {
            logger.warning("config for FirebaseService not found")

            self.firebase = nil
        }
        else {
            do {
                self.firebase = try FirebaseService(config: (self.config.firebase?.ios!)!)
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
        } else if self.config.facebook?.ios == nil {
            logger.warning("config for FacebookService not found")

            self.facebook = nil
        }
        else {
            do {
                self.facebook = try FacebookService(config: (self.config.facebook?.ios!)!)
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
    
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Any]) {
        if source.isEmpty {
            logger.error("source is empty")
            return
        }

        if revenue <= 0 {
            logger.error("revenue is negative or zero")
            return
        }

        if currency.isEmpty {
            logger.error("currency is empty")
            return
        }

        self.adjust?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
        self.firebase?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
        self.facebook?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
    }
    
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Any]) {
        if orderId.isEmpty {
            logger.error("orderId is empty")
            return
        }

        if amount <= 0 {
            logger.error("amount is negative or zero")
            return
        }

        if currency.isEmpty {
            logger.error("currency is empty")
            return
        }

        self.adjust?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
        self.firebase?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
        self.facebook?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
    }
    
    func trackCustomEvent(_ eventName: String, payload: [String:Any]) {
        self.adjust?.trackCustomEvent(eventName, payload: payload)
        self.firebase?.trackCustomEvent(eventName, payload: payload)
        self.facebook?.trackCustomEvent(eventName, payload: payload)
    }

    func purchaseItem(productId: String, completion: @escaping CompletionCallback) {
        logger.debug("productId: \(productId)")
        
        self.noctua?.purchaseItem(productId: productId, completion: completion)
    }

    func getActiveCurrency(productId: String, completion: @escaping CompletionCallback) {
        logger.debug("productId: \(productId)")
        
        self.noctua?.getActiveCurrency(productId: productId, completion: completion)
    }
    
    func putAccount(gameId: Int64, playerId: Int64, rawData: String) {
        let account = Account(playerId: playerId, gameId: gameId, rawData: rawData)
        
        accountRepo.put(account)
    }
    
    func getAllAccounts() -> [[String:Any]] {
        let accounts = accountRepo.getAll()
        
        return accounts.map {
            account in
            [
                "playerId": account.playerId,
                "gameId": account.gameId,
                "rawData": account.rawData,
                "lastUpdated": account.lastUpdated
            ]
        }
    }
    
    func getSingleAccount(gameId: Int64, playerId: Int64) -> [String:Any]? {
        let account = accountRepo.getSingle(gameId: gameId, playerId: playerId)
        
        if account == nil {
            return nil
        }
        
        return [
            "playerId": account!.playerId,
            "gameId": account!.gameId,
            "rawData": account!.rawData,
            "lastUpdated": account!.lastUpdated
        ]
    }
    
    func deleteAccount(gameId: Int64, playerId: Int64) {
        accountRepo.delete(gameId: gameId, playerId: playerId)
    }

    func onOnline() {
        self.adjust?.onOnline()
    }

    func onOffline() {
        self.adjust?.onOffline()
    }
    
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: NoctuaPlugin.self)
    )
}
