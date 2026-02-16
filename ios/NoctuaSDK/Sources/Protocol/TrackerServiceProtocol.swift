import Foundation

protocol TrackerServiceProtocol {
    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String: Any])
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String: Any])
    func trackCustomEvent(_ eventName: String, payload: [String: Any])
    func trackCustomEventWithRevenue(_ eventName: String, revenue: Double, currency: String, payload: [String: Any])
}
