import Foundation

class SessionPresenter {
    private let config: NoctuaConfig
    private let adjustSpecific: AdjustSpecificProtocol?
    private let firebaseQuery: FirebaseQueryServiceProtocol?
    private let noctuaInternal: NoctuaInternalServiceProtocol?
    private let logger: NoctuaLogger

    init(
        config: NoctuaConfig,
        adjustSpecific: AdjustSpecificProtocol?,
        firebaseQuery: FirebaseQueryServiceProtocol?,
        noctuaInternal: NoctuaInternalServiceProtocol?,
        logger: NoctuaLogger
    ) {
        self.config = config
        self.adjustSpecific = adjustSpecific
        self.firebaseQuery = firebaseQuery
        self.noctuaInternal = noctuaInternal
        self.logger = logger
    }

    // MARK: - Network State

    func onOnline() {
        adjustSpecific?.onOnline()
    }

    func onOffline() {
        adjustSpecific?.onOffline()
    }

    // MARK: - Firebase Queries

    func getFirebaseInstallationID(completion: @escaping (String) -> Void) {
        firebaseQuery?.getFirebaseInstallationID(completion: completion)
    }

    func getFirebaseSessionID(completion: @escaping (String) -> Void) {
        firebaseQuery?.getFirebaseSessionID(completion: completion)
    }

    func getFirebaseRemoteConfigString(key: String) -> String? {
        return firebaseQuery?.getFirebaseRemoteConfigString(key: key)
    }

    func getFirebaseRemoteConfigBoolean(key: String) -> Bool? {
        return firebaseQuery?.getFirebaseRemoteConfigBoolean(key: key)
    }

    func getFirebaseRemoteConfigDouble(key: String) -> Double? {
        return firebaseQuery?.getFirebaseRemoteConfigDouble(key: key)
    }

    func getFirebaseRemoteConfigLong(key: String) -> Int64? {
        return firebaseQuery?.getFirebaseRemoteConfigLong(key: key)
    }

    // MARK: - Session Tags

    func setSessionTag(tag: String) {
        guard config.noctua?.nativeInternalTrackerEnabled == true else {
            logger.debug("nativeInternalTrackerEnabled is not enabled")
            return
        }

        noctuaInternal?.setSessionTag(tag: tag)
    }

    func getSessionTag() -> String? {
        guard config.noctua?.nativeInternalTrackerEnabled == true else {
            logger.debug("nativeInternalTrackerEnabled is not enabled")
            return ""
        }

        return noctuaInternal?.getSessionTag() ?? ""
    }

    // MARK: - Experiments

    func setExperiment(experiment: String) {
        guard config.noctua?.nativeInternalTrackerEnabled == true else {
            logger.debug("nativeInternalTrackerEnabled is not enabled")
            return
        }

        noctuaInternal?.setExperiment(experiment: experiment)
    }

    func getExperiment() -> String? {
        guard config.noctua?.nativeInternalTrackerEnabled == true else {
            logger.debug("nativeInternalTrackerEnabled is not enabled")
            return ""
        }

        return noctuaInternal?.getExperiment() ?? ""
    }

    func setGeneralExperiment(experiment: String) {
        guard config.noctua?.nativeInternalTrackerEnabled == true else {
            logger.debug("nativeInternalTrackerEnabled is not enabled")
            return
        }

        noctuaInternal?.setGeneralExperiment(experiment: experiment)
    }

    func getGeneralExperiment(experimentKey: String) -> String? {
        guard config.noctua?.nativeInternalTrackerEnabled == true else {
            logger.debug("nativeInternalTrackerEnabled is not enabled")
            return ""
        }

        return noctuaInternal?.getGeneralExperiment(experimentKey: experimentKey) ?? ""
    }

    // MARK: - Session Extra Params

    func setSessionExtraParams(payload: [String: Any]) {
        guard config.noctua?.nativeInternalTrackerEnabled == true else {
            logger.debug("nativeInternalTrackerEnabled is not enabled")
            return
        }

        noctuaInternal?.setSessionExtraParams(params: payload)
    }

    // MARK: - Events

    func saveEvents(jsonString: String) {
        noctuaInternal?.saveExternalEvents(jsonString: jsonString)
    }

    func getEvents(onResult: @escaping ([String]) -> Void) {
        noctuaInternal?.getExternalEvents(onResult: onResult)
    }

    func deleteEvents() {
        noctuaInternal?.deleteExternalEvents()
    }

    // MARK: - Per-Row Events (Unlimited)

    func insertEvent(eventJson: String) {
        noctuaInternal?.insertExternalEvent(eventJson: eventJson)
    }

    func getEventsBatch(limit: Int32, offset: Int32, onResult: @escaping (String) -> Void) {
        noctuaInternal?.getExternalEventsBatch(limit: limit, offset: offset, onResult: onResult)
    }

    func deleteEventsByIds(idsJson: String, onResult: @escaping (Int32) -> Void) {
        noctuaInternal?.deleteExternalEventsByIds(idsJson: idsJson, onResult: onResult)
    }

    func getEventCount(onResult: @escaping (Int32) -> Void) {
        noctuaInternal?.getExternalEventCount(onResult: onResult)
    }

    // MARK: - Attribution

    func getAdjustCurrentAttribution(completion: @escaping ([String: Any]) -> Void) {
        if let adjustSpecific = adjustSpecific {
            adjustSpecific.getAdjustCurrentAttribution(completion: completion)
        } else {
            completion([:])
        }
    }
}
