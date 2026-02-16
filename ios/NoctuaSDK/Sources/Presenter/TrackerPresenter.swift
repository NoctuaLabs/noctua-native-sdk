import Foundation

class TrackerPresenter {
    private let config: NoctuaConfig
    private let trackers: [TrackerServiceProtocol]
    private let noctuaInternal: NoctuaInternalServiceProtocol?
    private let logger: NoctuaLogger

    init(
        config: NoctuaConfig,
        trackers: [TrackerServiceProtocol],
        noctuaInternal: NoctuaInternalServiceProtocol?,
        logger: NoctuaLogger
    ) {
        self.config = config
        self.trackers = trackers
        self.noctuaInternal = noctuaInternal
        self.logger = logger
    }

    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String: Any]) {
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

        for tracker in trackers {
            tracker.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
        }
    }

    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String: Any]) {
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

        for tracker in trackers {
            tracker.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
        }
    }

    func trackCustomEvent(_ eventName: String, payload: [String: Any]) {
        for tracker in trackers {
            tracker.trackCustomEvent(eventName, payload: payload)
        }

        if (config.noctua?.nativeInternalTrackerEnabled ?? false) {
            noctuaInternal?.trackCustomEvent(eventName: eventName, properties: payload)
        }
    }

    func trackCustomEventWithRevenue(_ eventName: String, revenue: Double, currency: String, payload: [String: Any]) {
        for tracker in trackers {
            tracker.trackCustomEventWithRevenue(eventName, revenue: revenue, currency: currency, payload: payload)
        }
    }
}
