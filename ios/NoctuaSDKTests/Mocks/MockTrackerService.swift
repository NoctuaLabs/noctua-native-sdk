import Foundation
@testable import NoctuaSDK

class MockTrackerService: TrackerServiceProtocol {
    struct AdRevenueCall {
        let source: String
        let revenue: Double
        let currency: String
        let extraPayload: [String: Any]
    }

    struct PurchaseCall {
        let orderId: String
        let amount: Double
        let currency: String
        let extraPayload: [String: Any]
    }

    struct CustomEventCall {
        let eventName: String
        let payload: [String: Any]
    }

    struct CustomEventWithRevenueCall {
        let eventName: String
        let revenue: Double
        let currency: String
        let payload: [String: Any]
    }

    var adRevenueCalls: [AdRevenueCall] = []
    var purchaseCalls: [PurchaseCall] = []
    var customEventCalls: [CustomEventCall] = []
    var customEventWithRevenueCalls: [CustomEventWithRevenueCall] = []

    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String: Any]) {
        adRevenueCalls.append(AdRevenueCall(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload))
    }

    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String: Any]) {
        purchaseCalls.append(PurchaseCall(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload))
    }

    func trackCustomEvent(_ eventName: String, payload: [String: Any]) {
        customEventCalls.append(CustomEventCall(eventName: eventName, payload: payload))
    }

    func trackCustomEventWithRevenue(_ eventName: String, revenue: Double, currency: String, payload: [String: Any]) {
        customEventWithRevenueCalls.append(CustomEventWithRevenueCall(eventName: eventName, revenue: revenue, currency: currency, payload: payload))
    }
}
