import Foundation

@objc public class Noctua: NSObject {
    @objc public static func initNoctua() throws {
        if plugin == nil {
            plugin = NoctuaPlugin(config: try loadConfig())
        }
    }
    
    @objc public static func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Any] = [:]) {
        plugin?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
    }
    
    @objc public static func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Any] = [:]) {
        plugin?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
    }
    
    @objc public static func trackCustomEvent(_ eventName: String, payload: [String:Any] = [:]) {
        plugin?.trackCustomEvent(eventName, payload: payload)
    }

    @objc public static func purchaseItem(_ productId: String, completion: @escaping (Bool, String) -> Void) {
        plugin?.purchaseItem(productId: productId, completion: completion)
    }

    @objc public static func getActiveCurrency(_ productId: String, completion: @escaping (Bool, String) -> Void) {
        plugin?.getActiveCurrency(productId: productId, completion: completion)
    }
    
    @objc public static func putAccount(gameId: Int64, playerId: Int64, rawData: String) {
        plugin?.putAccount(gameId: gameId, playerId: playerId, rawData: rawData)
    }
    
    @objc public static func getAllAccounts() -> [[String:Any]] {
        return plugin?.getAllAccounts() ?? []
    }
    
    @objc public static func getSingleAccount(gameId: Int64, playerId: Int64) -> [String:Any]? {
        return plugin?.getSingleAccount(gameId: gameId, playerId: playerId)
    }
    
    @objc public static func deleteAccount(gameId: Int64, playerId: Int64) {
        plugin?.deleteAccount(gameId: gameId, playerId: playerId)
    }

    @objc public static func onOnline() {
        plugin?.onOnline()
    }

    @objc public static func onOffline() {
        plugin?.onOffline()
    }
    
    static var plugin: NoctuaPlugin?
}

enum ConfigurationError: Error {
    case fileNotFound
    case invalidFormat
    case missingKey(String)
    case unknown(Error)
}

func loadConfig() throws -> NoctuaConfig {
    let firstPath = Bundle.main.path(forResource: "/Data/Raw/noctuagg", ofType: "json")
    let secondPath = Bundle.main.path(forResource: "noctuagg", ofType: "json")
    
    guard let path = firstPath ?? secondPath else {
        throw ConfigurationError.fileNotFound
    }
    
    let config: NoctuaConfig
    
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        config = try JSONDecoder().decode(NoctuaConfig.self, from: data)
    } 
    catch DecodingError.valueNotFound(let type, let context) {
        throw ConfigurationError.missingKey("type: \(type), desc: \(context.debugDescription)")
    } 
    catch DecodingError.keyNotFound(let key, let context) {
        throw ConfigurationError.missingKey("type: \(key), desc: \(context.debugDescription)")
    }
    catch {
        throw ConfigurationError.invalidFormat
    }
    
    if config.clientId.isEmpty {
        throw ConfigurationError.missingKey("clientId")
    }
    
    return config
}
