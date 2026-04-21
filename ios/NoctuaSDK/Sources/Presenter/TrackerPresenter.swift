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

        let payload: [String: Any] = [
            "source": source,
            "revenue": revenue,
            "currency": currency,
            "extraPayload": extraPayload
        ]

        for tracker in trackers {
            NoctuaInspectorBus.shared.emit(
                provider: tracker.providerName,
                eventName: "ad_revenue",
                payload: payload,
                phase: .queued
            )
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

        let payload: [String: Any] = [
            "orderId": orderId,
            "amount": amount,
            "currency": currency,
            "extraPayload": extraPayload
        ]

        for tracker in trackers {
            NoctuaInspectorBus.shared.emit(
                provider: tracker.providerName,
                eventName: "purchase",
                payload: payload,
                phase: .queued
            )
            tracker.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
        }
    }

    func trackCustomEvent(_ eventName: String, payload: [String: Any]) {
        for tracker in trackers {
            NoctuaInspectorBus.shared.emit(
                provider: tracker.providerName,
                eventName: eventName,
                payload: payload,
                phase: .queued
            )
            // Register pending for every provider with a log-tailer so the
            // tailer can correlate the next `Emitted` / `Acknowledged` line
            // back to this specific dispatch.
            if tracker.providerName == "Firebase" ||
               tracker.providerName == "Facebook" ||
               tracker.providerName == "Adjust" {
                FirebaseLogTailer.shared.registerPending(
                    provider: tracker.providerName,
                    eventName: eventName
                )
            }
            tracker.trackCustomEvent(eventName, payload: payload)
        }

        if (config.noctua?.nativeInternalTrackerEnabled ?? false) {
            noctuaInternal?.trackCustomEvent(eventName: eventName, properties: payload)
        }
    }

    func trackCustomEventWithRevenue(_ eventName: String, revenue: Double, currency: String, payload: [String: Any]) {
        var enriched = payload
        enriched["revenue"] = revenue
        enriched["currency"] = currency

        for tracker in trackers {
            NoctuaInspectorBus.shared.emit(
                provider: tracker.providerName,
                eventName: eventName,
                payload: enriched,
                phase: .queued
            )
            tracker.trackCustomEventWithRevenue(eventName, revenue: revenue, currency: currency, payload: payload)
        }
    }
}
