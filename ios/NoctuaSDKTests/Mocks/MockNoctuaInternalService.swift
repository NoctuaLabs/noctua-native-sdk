import Foundation
@testable import NoctuaSDK

class MockNoctuaInternalService: NoctuaInternalServiceProtocol {
    var initializeCalled = false
    var trackedCustomEvents: [(String, [String: Any])] = []
    var sessionTag: String? = nil
    var experiment: String? = nil
    var generalExperiments: [String: String] = [:]
    var sessionExtraParams: [String: Any]? = nil
    var savedEvents: String? = nil
    var externalEventsToReturn: [String] = []
    var deleteExternalEventsCalled = false
    var insertedEvents: [String] = []
    var eventBatchResult: String = "[]"
    var deletedEventIds: [String] = []
    var deletedEventIdsResult: Int32 = 1
    var eventCount: Int32 = 0

    func initialize() {
        initializeCalled = true
    }

    func trackCustomEvent(eventName: String, properties: [String: Any]) {
        trackedCustomEvents.append((eventName, properties))
    }

    func setSessionTag(tag: String) {
        sessionTag = tag
    }

    func getSessionTag() -> String? {
        return sessionTag
    }

    func setExperiment(experiment: String) {
        self.experiment = experiment
    }

    func getExperiment() -> String? {
        return experiment
    }

    func setGeneralExperiment(experiment: String) {
        generalExperiments["default"] = experiment
    }

    func getGeneralExperiment(experimentKey: String) -> String? {
        return generalExperiments[experimentKey]
    }

    func setSessionExtraParams(params: [String: Any]) {
        sessionExtraParams = params
    }

    func saveExternalEvents(jsonString: String) {
        savedEvents = jsonString
    }

    func getExternalEvents(onResult: @escaping ([String]) -> Void) {
        onResult(externalEventsToReturn)
    }

    func deleteExternalEvents() {
        deleteExternalEventsCalled = true
    }

    func insertExternalEvent(eventJson: String) {
        insertedEvents.append(eventJson)
    }

    func getExternalEventsBatch(limit: Int32, offset: Int32, onResult: @escaping (String) -> Void) {
        onResult(eventBatchResult)
    }

    func deleteExternalEventsByIds(idsJson: String, onResult: @escaping (Int32) -> Void) {
        deletedEventIds.append(idsJson)
        onResult(deletedEventIdsResult)
    }

    func getExternalEventCount(onResult: @escaping (Int32) -> Void) {
        onResult(eventCount)
    }
}
