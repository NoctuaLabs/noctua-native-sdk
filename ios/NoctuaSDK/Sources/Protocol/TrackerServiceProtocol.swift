import Foundation

protocol TrackerServiceProtocol {
    /// Canonical provider name surfaced to the Inspector (e.g. "Firebase",
    /// "Adjust", "Facebook"). Must be stable — Inspector uses this as the
    /// correlation/filter key on the Trackers tab.
    var providerName: String { get }

    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String: Any])
    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String: Any])
    func trackCustomEvent(_ eventName: String, payload: [String: Any])
    func trackCustomEventWithRevenue(_ eventName: String, revenue: Double, currency: String, payload: [String: Any])
}
