import Foundation
#if canImport(NoctuaInternalSDK)
import NoctuaInternalSDK
#endif

class NoctuaInternalService: NoctuaInternalServiceProtocol {

    func initialize() {
        #if canImport(NoctuaInternalSDK)
        Utils_iosKt.doInitKoinManually()
        #endif
    }

    func trackCustomEvent(eventName: String, properties: [String: Any]) {
        #if canImport(NoctuaInternalSDK)
        NoctuaInternal.shared.trackCustomEvent(eventName: eventName, properties: properties)
        #endif
    }

    func setSessionTag(tag: String) {
        #if canImport(NoctuaInternalSDK)
        NoctuaInternal.shared.setSessionTag(tag: tag)
        #endif
    }

    func getSessionTag() -> String? {
        #if canImport(NoctuaInternalSDK)
        return NoctuaInternal.shared.getSessionTag()
        #else
        return ""
        #endif
    }

    func setExperiment(experiment: String) {
        #if canImport(NoctuaInternalSDK)
        NoctuaInternal.shared.setExperiment(experiment: experiment)
        #endif
    }

    func getExperiment() -> String? {
        #if canImport(NoctuaInternalSDK)
        return NoctuaInternal.shared.getExperiment()
        #else
        return ""
        #endif
    }

    func setGeneralExperiment(experiment: String) {
        #if canImport(NoctuaInternalSDK)
        NoctuaInternal.shared.setGeneralExperiment(experiment: experiment)
        #endif
    }

    func getGeneralExperiment(experimentKey: String) -> String? {
        #if canImport(NoctuaInternalSDK)
        return NoctuaInternal.shared.getGeneralExperiment(experimentKey: experimentKey)
        #else
        return ""
        #endif
    }

    func setSessionExtraParams(params: [String: Any]) {
        #if canImport(NoctuaInternalSDK)
        NoctuaInternal.shared.setSessionExtraParams(params: params)
        #endif
    }

    func saveExternalEvents(jsonString: String) {
        #if canImport(NoctuaInternalSDK)
        NoctuaInternal.shared.saveExternalEvents(jsonString: jsonString)
        #endif
    }

    func getExternalEvents(onResult: @escaping ([String]) -> Void) {
        #if canImport(NoctuaInternalSDK)
        NoctuaInternal.shared.getExternalEvents(onResult: onResult)
        #endif
    }

    func deleteExternalEvents() {
        #if canImport(NoctuaInternalSDK)
        NoctuaInternal.shared.deleteExternalEvents()
        #endif
    }

    // MARK: - Per-Row Event Storage (Unlimited)

    func insertExternalEvent(eventJson: String) {
        #if canImport(NoctuaInternalSDK)
        NoctuaInternal.shared.insertExternalEvent(eventJson: eventJson)
        #endif
    }

    func getExternalEventsBatch(limit: Int32, offset: Int32, onResult: @escaping (String) -> Void) {
        #if canImport(NoctuaInternalSDK)
        NoctuaInternal.shared.getExternalEventsBatch(limit: limit, offset: offset, callback: onResult)
        #endif
    }

    func deleteExternalEventsByIds(idsJson: String, onResult: @escaping (Int32) -> Void) {
        #if canImport(NoctuaInternalSDK)
        NoctuaInternal.shared.deleteExternalEventsByIds(idsJson: idsJson, callback: onResult)
        #endif
    }

    func getExternalEventCount(onResult: @escaping (Int32) -> Void) {
        #if canImport(NoctuaInternalSDK)
        NoctuaInternal.shared.getExternalEventCount(callback: onResult)
        #endif
    }
}
