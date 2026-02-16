import Foundation

@objc public class Noctua: NSObject {
    @objc public static func initNoctua() throws {
        if tracker == nil && iap == nil && account == nil && session == nil {
            let config = try loadConfig()
            let logger = IOSLogger(category: "Noctua")

            let services = buildServices(config: config, logger: logger)

            tracker = TrackerPresenter(
                config: config,
                trackers: services.trackers,
                noctuaInternal: services.noctuaInternal,
                logger: logger
            )

            iap = IAPPresenter(
                iapService: services.iapService,
                logger: logger
            )

            account = AccountPresenter(
                accountRepo: services.accountRepo,
                logger: logger
            )

            session = SessionPresenter(
                config: config,
                adjustSpecific: services.adjustSpecific,
                firebaseQuery: services.firebaseQuery,
                noctuaInternal: services.noctuaInternal,
                logger: logger
            )
        }
    }

    @objc public static func trackAdRevenue(source: String, revenue: Double, currency: String, extraPayload: [String: Any] = [:]) {
        tracker?.trackAdRevenue(source: source, revenue: revenue, currency: currency, extraPayload: extraPayload)
    }

    @objc public static func trackPurchase(orderId: String, amount: Double, currency: String, extraPayload: [String: Any] = [:]) {
        tracker?.trackPurchase(orderId: orderId, amount: amount, currency: currency, extraPayload: extraPayload)
    }

    @objc public static func trackCustomEvent(_ eventName: String, payload: [String: Any] = [:]) {
        tracker?.trackCustomEvent(eventName, payload: payload)
    }

    @objc public static func trackCustomEventWithRevenue(_ eventName: String, revenue: Double, currency: String, payload: [String: Any] = [:]) {
        tracker?.trackCustomEventWithRevenue(eventName, revenue: revenue, currency: currency, payload: payload)
    }

    @objc public static func purchaseItem(_ productId: String, completion: @escaping (Bool, String) -> Void) {
        iap?.purchaseItem(productId: productId, completion: completion)
    }

    @objc public static func getProductPurchasedById(id productId: String, completion: @escaping (Bool) -> Void) async {
        await iap?.getProductPurchasedById(id: productId, completion: completion)
    }

    @objc public static func getReceiptProductPurchasedStoreKit1(id productId: String, completion: @escaping (String) -> Void) {
        iap?.getReceiptProductPurchasedStoreKit1(id: productId, completion: completion)
    }

    @objc public static func getActiveCurrency(_ productId: String, completion: @escaping (Bool, String) -> Void) {
        iap?.getActiveCurrency(productId: productId, completion: completion)
    }

    @objc public static func putAccount(gameId: Int64, playerId: Int64, rawData: String) {
        account?.putAccount(gameId: gameId, playerId: playerId, rawData: rawData)
    }

    @objc public static func getAllAccounts() -> [[String: Any]] {
        return account?.getAllAccounts() ?? []
    }

    @objc public static func getSingleAccount(gameId: Int64, playerId: Int64) -> [String: Any]? {
        return account?.getSingleAccount(gameId: gameId, playerId: playerId)
    }

    @objc public static func deleteAccount(gameId: Int64, playerId: Int64) {
        account?.deleteAccount(gameId: gameId, playerId: playerId)
    }

    @objc public static func onOnline() {
        session?.onOnline()
    }

    @objc public static func onOffline() {
        session?.onOffline()
    }

    @objc public static func getFirebaseInstallationID(completion: @escaping (String) -> Void) {
        session?.getFirebaseInstallationID(completion: completion)
    }

    @objc public static func getFirebaseSessionID(completion: @escaping (String) -> Void) {
        session?.getFirebaseSessionID(completion: completion)
    }

    @objc public static func getFirebaseRemoteConfigString(key: String) -> String? {
        return session?.getFirebaseRemoteConfigString(key: key)
    }

    @objc public static func getFirebaseRemoteConfigBoolean(key: String) -> Bool {
        return session?.getFirebaseRemoteConfigBoolean(key: key) ?? false
    }

    @objc public static func getFirebaseRemoteConfigDouble(key: String) -> Double {
        return session?.getFirebaseRemoteConfigDouble(key: key) ?? 0.0
    }

    @objc public static func getFirebaseRemoteConfigLong(key: String) -> Int64 {
        return session?.getFirebaseRemoteConfigLong(key: key) ?? 0
    }

    @objc public static func setSessionTag(tag: String) {
        session?.setSessionTag(tag: tag)
    }

    @objc public static func getSessionTags() -> String? {
        return session?.getSessionTag()
    }

    @objc public static func setExperiment(experiment: String) {
        session?.setExperiment(experiment: experiment)
    }

    @objc public static func getExperiment() -> String? {
        return session?.getExperiment()
    }

    @objc public static func setGeneralExperiment(experiment: String) {
        session?.setGeneralExperiment(experiment: experiment)
    }

    @objc public static func getGeneralExperiment(experimentKey: String) -> String? {
        return session?.getGeneralExperiment(experimentKey: experimentKey)
    }

    @objc public static func setSessionExtraParams(payload: [String: Any]) {
        session?.setSessionExtraParams(payload: payload)
    }

    @objc public static func saveEvents(jsonString: String) {
        session?.saveEvents(jsonString: jsonString)
    }

    @objc public static func getEvents(onResult: @escaping ([String]) -> Void) {
        session?.getEvents(onResult: onResult)
    }

    @objc public static func deleteEvents() {
        session?.deleteEvents()
    }

    @objc public static func getAdjustCurrentAttribution() -> [String: Any] {
        return session?.getAdjustCurrentAttribution() ?? [:]
    }

    // MARK: - Private

    private static var tracker: TrackerPresenter?
    private static var iap: IAPPresenter?
    private static var account: AccountPresenter?
    private static var session: SessionPresenter?

    private static func buildServices(config: NoctuaConfig, logger: NoctuaLogger) -> (
        trackers: [TrackerServiceProtocol],
        iapService: IAPServiceProtocol?,
        adjustSpecific: AdjustSpecificProtocol?,
        firebaseQuery: FirebaseQueryServiceProtocol?,
        noctuaInternal: NoctuaInternalServiceProtocol?,
        accountRepo: AccountRepositoryProtocol
    ) {
        // Initialize NoctuaInternal first (Koin must init before other services)
        let noctuaInternal = NoctuaInternalService()
        noctuaInternal.initialize()

        var trackers: [TrackerServiceProtocol] = []
        var adjustSpecific: AdjustSpecificProtocol? = nil
        var firebaseQuery: FirebaseQueryServiceProtocol? = nil
        var iapService: IAPServiceProtocol? = nil

        // NoctuaService (IAP)
        if config.noctua == nil {
            logger.warning("config for NoctuaService not found")
        } else {
            let service = NoctuaService(config: config.noctua!, logger: logger)
            iapService = service
            logger.info("NoctuaService initialized")
        }

        // AdjustService
        if config.adjust == nil {
            logger.warning("config for AdjustService not found")
        } else if config.adjust?.ios == nil {
            logger.warning("config for AdjustService IOS not found")
        } else {
            do {
                let service = try AdjustService(config: (config.adjust?.ios!)!, logger: logger)
                trackers.append(service)
                adjustSpecific = service
                logger.info("AdjustService initialized")
            } catch AdjustServiceError.adjustNotFound {
                logger.warning("Adjust disabled, Adjust module not found")
            } catch AdjustServiceError.invalidConfig(let message) {
                logger.warning("Adjust disabled, invalid Adjust config: \(message)")
            } catch {
                logger.warning("Adjust disabled, unknown error")
            }
        }

        // FirebaseService
        if config.firebase == nil {
            logger.warning("config for FirebaseService not found")
        } else if config.firebase?.ios == nil {
            logger.warning("config for FirebaseService not found")
        } else {
            do {
                let service = try FirebaseService(config: (config.firebase?.ios!)!, logger: logger)
                trackers.append(service)
                firebaseQuery = service
                logger.info("FirebaseService initialized")
            } catch FirebaseServiceError.firebaseNotFound {
                logger.warning("Firebase disabled, Firebase module not found")
            } catch FirebaseServiceError.invalidConfig(let message) {
                logger.warning("Firebase disabled, invalid Firebase config: \(message)")
            } catch {
                logger.warning("Firebase disabled, unknown error")
            }
        }

        // FacebookService
        if config.facebook == nil {
            logger.warning("config for FacebookService not found")
        } else if config.facebook?.ios == nil {
            logger.warning("config for FacebookService not found")
        } else {
            do {
                let service = try FacebookService(config: (config.facebook?.ios!)!, logger: logger)
                trackers.append(service)
                logger.info("FacebookService initialized")
            } catch FacebookServiceError.facebookNotFound {
                logger.warning("Facebook disabled, Facebook module not found")
            } catch FacebookServiceError.invalidConfig(let message) {
                logger.warning("Facebook disabled, invalid Facebook config: \(message)")
            } catch {
                logger.warning("Facebook disabled, unknown error")
            }
        }

        let accountRepo = AccountRepository(logger: logger)

        return (trackers, iapService, adjustSpecific, firebaseQuery, noctuaInternal, accountRepo)
    }
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
