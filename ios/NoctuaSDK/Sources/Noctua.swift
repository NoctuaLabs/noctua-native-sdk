import Foundation

@objc public class Noctua: NSObject {
    @objc public static func initNoctua() throws {
        plugin = NoctuaPlugin(config: try loadConfig())
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
        print("Noctua SDK Native: Noctua.purchaseItem called with productId: \(productId)")
        plugin?.purchaseItem(productId: productId, completion: completion)
    }

    @objc public static func getActiveCurrency(_ productId: String, completion: @escaping (Bool, String) -> Void) {
        print("Noctua SDK Native: Noctua.getActiveCurrency called with productId: \(productId)")
        plugin?.getActiveCurrency(productId: productId, completion: completion)
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
    } catch {
        throw ConfigurationError.invalidFormat
    }
    
    if config.clientId.isEmpty {
        throw ConfigurationError.missingKey("clientId")
    }
    
    return config
}
