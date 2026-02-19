import Foundation
#if canImport(AdjustSdk)
import AdjustSdk
#endif

class AdjustService: TrackerServiceProtocol, AdjustSpecificProtocol {
    let config: AdjustServiceIosConfig
    private let logger: NoctuaLogger

    init(config: AdjustServiceIosConfig, logger: NoctuaLogger = IOSLogger(category: "AdjustService")) throws {
#if canImport(AdjustSdk)
        self.config = config
        self.logger = logger

        guard let eventMap = config.eventMap, !eventMap.isEmpty else {
            throw AdjustServiceError.invalidConfig("eventMap is empty")
        }

        guard eventMap.keys.contains("purchase") else {
            throw AdjustServiceError.invalidConfig("no eventToken for purchase")
        }

        let environment = config.environment?.isEmpty ?? true ? "sandbox" : config.environment!

        let appToken = config.appToken
        guard !appToken.isEmpty else {
            throw AdjustServiceError.invalidConfig("appToken is empty")
        }
        let adjustConfig = ADJConfig(appToken: appToken, environment: environment)
        adjustConfig?.logLevel = if config.environment == "production" { ADJLogLevel.warn } else { ADJLogLevel.debug }
        adjustConfig?.enableCostDataInAttribution()

        Adjust.initSdk(adjustConfig)
#else
        throw AdjustServiceError.adjustNotFound
#endif
    }

    func getAdjustCurrentAttribution(completion: @escaping ([String: Any]) -> Void) {
    #if canImport(AdjustSdk)
        Adjust.attribution { attribution in
            guard let attribution = attribution else {
                completion([:])
                return
            }

            completion([
                "trackerToken": attribution.trackerToken ?? "",
                "trackerName": attribution.trackerName ?? "",
                "network": attribution.network ?? "",
                "campaign": attribution.campaign ?? "",
                "adgroup": attribution.adgroup ?? "",
                "creative": attribution.creative ?? "",
                "clickLabel": attribution.clickLabel ?? "",
                "costType": attribution.costType ?? "",
                "costAmount": attribution.costAmount?.doubleValue ?? 0,
                "costCurrency": attribution.costCurrency ?? ""
            ])
        }
    #else
        completion([:])
    #endif
    }

    func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String: Any]) {
#if canImport(AdjustSdk)
        let adRevenue = ADJAdRevenue(source: source)!
        adRevenue.setRevenue(revenue, currency: currency)

        for (key, value) in extraPayload {
            adRevenue.addCallbackParameter(key, value: "\(value)")
        }

        Adjust.trackAdRevenue(adRevenue)
#endif
    }

    func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String: Any]) {
#if canImport(AdjustSdk)
        let eventToken = config.eventMap?["purchase"] ?? ""
        guard !eventToken.isEmpty else {
            logger.warning("no eventToken for purchase")
            return
        }
        let purchase = ADJEvent(eventToken: eventToken)!
        purchase.setTransactionId(orderId)
        purchase.setRevenue(amount, currency: currency)

        for (key, value) in extraPayload {
            purchase.addCallbackParameter(key, value: "\(value)")
        }

        Adjust.trackEvent(purchase)
#endif
    }

    func trackCustomEvent(_ eventName: String, payload: [String: Any]) {
#if canImport(AdjustSdk)
        if (config.customEventDisabled ?? false) {
            logger.warning("custom event is disabled")
            return
        }

        guard let eventToken = config.eventMap?[eventName] else {
            logger.warning("no eventToken for \(eventName)")
            return
        }

        guard !eventToken.isEmpty else {
            logger.warning("no eventToken for \(eventName)")
            return
        }

        let event = ADJEvent(eventToken: eventToken)!

        for (key, value) in payload {
            event.addCallbackParameter(key, value: "\(value)")
        }

        Adjust.trackEvent(event)
#endif
    }

    func trackCustomEventWithRevenue(_ eventName: String, revenue: Double, currency: String, payload: [String: Any]) {
#if canImport(AdjustSdk)
        if (config.customEventDisabled ?? false) {
            logger.warning("custom event is disabled")
            return
        }

        guard let eventToken = config.eventMap?[eventName] else {
            logger.warning("no eventToken for \(eventName)")
            return
        }

        guard !eventToken.isEmpty else {
            logger.warning("no eventToken for \(eventName)")
            return
        }

        let event = ADJEvent(eventToken: eventToken)!

        var extraPayload = payload
        extraPayload["revenue"] = revenue
        extraPayload["currency"] = currency

        for (key, value) in extraPayload {
            event.addCallbackParameter(key, value: "\(value)")
        }

        Adjust.trackEvent(event)
#endif
    }

    func onOnline() {
#if canImport(AdjustSdk)
        Adjust.switchBackToOnlineMode()
#endif
    }

    func onOffline() {
#if canImport(AdjustSdk)
        Adjust.switchToOfflineMode()
#endif
    }
}
