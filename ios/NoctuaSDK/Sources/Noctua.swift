//
//  Noctua.swift
//  NoctuaSDK
//
//  Created by SDK Dev on 31/07/24.
//

import Foundation

public class Noctua {
    public static func initialize() throws {
        let config = try loadConfig()
        
        plugin = NoctuaPlugin(config: config)
    }
    
    public static func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String:Encodable] = [:]) {
        plugin?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
    }
    
    public static func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String:Encodable] = [:]) {
        plugin?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
    }
    
    public static func trackCustomEvent(_ eventName: String, payload: [String:Encodable] = [:]) {
        plugin?.trackCustomEvent(eventName, payload: payload)
    }
    
    static var plugin: NoctuaPlugin?
}
