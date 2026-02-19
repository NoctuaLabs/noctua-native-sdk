import Foundation

@objc public class Noctua: NSObject {
    @objc public static func initNoctua() throws {
        if tracker == nil && storeKit == nil && account == nil && session == nil {
            let config = try loadConfig()
            let logger = IOSLogger(category: "Noctua")

            let services = buildServices(config: config, logger: logger)

            tracker = TrackerPresenter(
                config: config,
                trackers: services.trackers,
                noctuaInternal: services.noctuaInternal,
                logger: logger
            )

            storeKit = StoreKitPresenter(
                storeKitService: services.storeKitService,
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

    // MARK: - Tracking

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

    // MARK: - StoreKit / In-App Purchases

    @objc public static func initializeStoreKit(
        onPurchaseCompleted: ((NoctuaPurchaseResult) -> Void)? = nil,
        onPurchaseUpdated: ((NoctuaPurchaseResult) -> Void)? = nil,
        onProductDetailsLoaded: (([NoctuaProductDetails]) -> Void)? = nil,
        onQueryPurchasesCompleted: (([NoctuaPurchaseResult]) -> Void)? = nil,
        onRestorePurchasesCompleted: (([NoctuaPurchaseResult]) -> Void)? = nil,
        onProductPurchaseStatusResult: ((NoctuaProductPurchaseStatus) -> Void)? = nil,
        onServerVerificationRequired: ((NoctuaPurchaseResult, ConsumableType) -> Void)? = nil,
        onStoreKitError: ((StoreKitErrorCode, String) -> Void)? = nil
    ) {
        storeKit?.initializeStoreKit(
            onPurchaseCompleted: onPurchaseCompleted,
            onPurchaseUpdated: onPurchaseUpdated,
            onProductDetailsLoaded: onProductDetailsLoaded,
            onQueryPurchasesCompleted: onQueryPurchasesCompleted,
            onRestorePurchasesCompleted: onRestorePurchasesCompleted,
            onProductPurchaseStatusResult: onProductPurchaseStatusResult,
            onServerVerificationRequired: onServerVerificationRequired,
            onStoreKitError: onStoreKitError
        )
    }

    @objc public static func registerProduct(productId: String, consumableType: ConsumableType) {
        storeKit?.registerProduct(productId: productId, consumableType: consumableType)
    }

    @objc public static func queryProductDetails(productIds: [String], productType: ProductType = .inapp) {
        storeKit?.queryProductDetails(productIds: productIds, productType: productType)
    }

    @objc public static func purchase(productId: String) {
        storeKit?.purchase(productId: productId)
    }

    @objc public static func queryPurchases(productType: ProductType = .inapp) {
        storeKit?.queryPurchases(productType: productType)
    }

    @objc public static func restorePurchases() {
        storeKit?.restorePurchases()
    }

    @objc public static func getProductPurchaseStatus(productId: String) {
        storeKit?.getProductPurchaseStatus(productId: productId)
    }

    @objc public static func completePurchaseProcessing(
        purchaseToken: String,
        consumableType: ConsumableType,
        verified: Bool,
        callback: ((Bool) -> Void)? = nil
    ) {
        storeKit?.completePurchaseProcessing(
            purchaseToken: purchaseToken,
            consumableType: consumableType,
            verified: verified,
            callback: callback
        )
    }

    @objc public static func disposeStoreKit() {
        storeKit?.disposeStoreKit()
    }

    @objc public static func isStoreKitReady() -> Bool {
        return storeKit?.isStoreKitReady() ?? false
    }

    // MARK: - Accounts

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

    // MARK: - Session & Lifecycle

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

    // MARK: - Per-Row Event Storage (Unlimited)

    @objc public static func insertEvent(eventJson: String) {
        session?.insertEvent(eventJson: eventJson)
    }

    @objc public static func getEventsBatch(limit: Int32, offset: Int32, onResult: @escaping (String) -> Void) {
        session?.getEventsBatch(limit: limit, offset: offset, onResult: onResult)
    }

    @objc public static func deleteEventsByIds(idsJson: String, onResult: @escaping (Int32) -> Void) {
        session?.deleteEventsByIds(idsJson: idsJson, onResult: onResult)
    }

    @objc public static func getEventCount(onResult: @escaping (Int32) -> Void) {
        session?.getEventCount(onResult: onResult)
    }

    @objc public static func getAdjustCurrentAttribution(completion: @escaping ([String: Any]) -> Void) {
        if let session = session {
            session.getAdjustCurrentAttribution(completion: completion)
        } else {
            completion([:])
        }
    }

    // MARK: - Currency Query (Delegated IAP)

    /// Queries the App Store for a product's currency code using SKProductsRequest.
    /// This is a read-only query — no SKPaymentTransactionObserver is added,
    /// so it will NOT conflict with game developers' own IAP implementations.
    @objc public static func getActiveCurrency(_ productId: String, completion: @escaping (Bool, String) -> Void) {
        if currencyQuery == nil {
            currencyQuery = CurrencyQueryService()
        }
        currencyQuery?.getActiveCurrency(productId: productId, completion: completion)
    }

    // MARK: - Private

    private static var tracker: TrackerPresenter?
    private static var storeKit: StoreKitPresenter?
    private static var account: AccountPresenter?
    private static var session: SessionPresenter?
    private static var currencyQuery: CurrencyQueryService?

    private static func buildServices(config: NoctuaConfig, logger: NoctuaLogger) -> (
        trackers: [TrackerServiceProtocol],
        storeKitService: StoreKitServiceProtocol?,
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

        // StoreKit Service (StoreKit 2, requires iOS 15+)
        let storeKitService: StoreKitServiceProtocol?
        if config.noctua?.iapDisabled == true {
            storeKitService = nil
            logger.info("StoreKit disabled by config (iapDisabled: true)")
        } else {
            let storeKitConfig = NoctuaStoreKitConfig()
            storeKitService = StoreKitService(config: storeKitConfig, logger: logger)
            logger.info("StoreKitService initialized (StoreKit 2)")
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

        return (trackers, storeKitService, adjustSpecific, firebaseQuery, noctuaInternal, accountRepo)
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
