import Foundation

protocol NoctuaInternalServiceProtocol {
    func initialize()
    func trackCustomEvent(eventName: String, properties: [String: Any])
    func setSessionTag(tag: String)
    func getSessionTag() -> String?
    func setExperiment(experiment: String)
    func getExperiment() -> String?
    func setGeneralExperiment(experiment: String)
    func getGeneralExperiment(experimentKey: String) -> String?
    func setSessionExtraParams(params: [String: Any])
    func saveExternalEvents(jsonString: String)
    func getExternalEvents(onResult: @escaping ([String]) -> Void)
    func deleteExternalEvents()

    // Per-row event storage for unlimited event tracking
    func insertExternalEvent(eventJson: String)
    func getExternalEventsBatch(limit: Int32, offset: Int32, onResult: @escaping (String) -> Void)
    func deleteExternalEventsByIds(idsJson: String, onResult: @escaping (Int32) -> Void)
    func getExternalEventCount(onResult: @escaping (Int32) -> Void)
}
