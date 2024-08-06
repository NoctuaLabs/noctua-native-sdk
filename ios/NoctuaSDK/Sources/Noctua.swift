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
    
    static var plugin: NoctuaPlugin?
}

enum ConfigurationError: Error {
    case fileNotFound
    case invalidFormat
    case missingKey(String)
    case unknown(Error)
}

func loadConfig() throws -> NoctuaConfig {
    guard let path = Bundle.main.path(forResource: "noctuagg", ofType: "json") else {
        throw ConfigurationError.fileNotFound
    }
    
    let config: NoctuaConfig
    
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        config = try JSONDecoder().decode(NoctuaConfig.self, from: data)
    } catch {
        throw ConfigurationError.invalidFormat
    }
    
    if config.productCode.isEmpty {
        throw ConfigurationError.missingKey("productCode")
    }
    
    return config
}
