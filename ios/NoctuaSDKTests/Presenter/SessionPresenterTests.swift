import XCTest
@testable import NoctuaSDK

class SessionPresenterTests: XCTestCase {

    var mockAdjust: MockAdjustSpecific!
    var mockFirebase: MockFirebaseQueryService!
    var mockNoctuaInternal: MockNoctuaInternalService!
    var logger: MockNoctuaLogger!

    override func setUp() {
        super.setUp()
        mockAdjust = MockAdjustSpecific()
        mockFirebase = MockFirebaseQueryService()
        mockNoctuaInternal = MockNoctuaInternalService()
        logger = MockNoctuaLogger()
    }

    private func makePresenter(
        nativeInternalTrackerEnabled: Bool? = nil,
        adjustSpecific: AdjustSpecificProtocol? = nil,
        firebaseQuery: FirebaseQueryServiceProtocol? = nil,
        noctuaInternal: NoctuaInternalServiceProtocol? = nil
    ) -> SessionPresenter {
        let config = TestConfigFactory.makeConfig(nativeInternalTrackerEnabled: nativeInternalTrackerEnabled)
        return SessionPresenter(
            config: config,
            adjustSpecific: adjustSpecific,
            firebaseQuery: firebaseQuery,
            noctuaInternal: noctuaInternal,
            logger: logger
        )
    }

    // MARK: - Network State

    func testOnOnlineDelegatesToAdjust() {
        let presenter = makePresenter(adjustSpecific: mockAdjust)
        presenter.onOnline()
        XCTAssertTrue(mockAdjust.onOnlineCalled)
    }

    func testOnOfflineDelegatesToAdjust() {
        let presenter = makePresenter(adjustSpecific: mockAdjust)
        presenter.onOffline()
        XCTAssertTrue(mockAdjust.onOfflineCalled)
    }

    func testOnOnlineNilAdjust() {
        let presenter = makePresenter(adjustSpecific: nil)
        // Should not crash
        presenter.onOnline()
    }

    func testOnOfflineNilAdjust() {
        let presenter = makePresenter(adjustSpecific: nil)
        // Should not crash
        presenter.onOffline()
    }

    // MARK: - Firebase Queries

    func testGetFirebaseInstallationID() {
        let presenter = makePresenter(firebaseQuery: mockFirebase)
        let expectation = XCTestExpectation(description: "installation id")

        presenter.getFirebaseInstallationID { id in
            XCTAssertEqual(id, "mock-installation-id")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetFirebaseSessionID() {
        let presenter = makePresenter(firebaseQuery: mockFirebase)
        let expectation = XCTestExpectation(description: "session id")

        presenter.getFirebaseSessionID { id in
            XCTAssertEqual(id, "mock-session-id")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetFirebaseRemoteConfigString() {
        mockFirebase.remoteConfigStrings["test_key"] = "test_value"
        let presenter = makePresenter(firebaseQuery: mockFirebase)

        let result = presenter.getFirebaseRemoteConfigString(key: "test_key")
        XCTAssertEqual(result, "test_value")
    }

    func testGetFirebaseRemoteConfigBoolean() {
        mockFirebase.remoteConfigBooleans["feature_flag"] = true
        let presenter = makePresenter(firebaseQuery: mockFirebase)

        let result = presenter.getFirebaseRemoteConfigBoolean(key: "feature_flag")
        XCTAssertEqual(result, true)
    }

    func testGetFirebaseRemoteConfigDouble() {
        mockFirebase.remoteConfigDoubles["price"] = 9.99
        let presenter = makePresenter(firebaseQuery: mockFirebase)

        let result = presenter.getFirebaseRemoteConfigDouble(key: "price")
        XCTAssertEqual(result, 9.99)
    }

    func testGetFirebaseRemoteConfigLong() {
        mockFirebase.remoteConfigLongs["count"] = 42
        let presenter = makePresenter(firebaseQuery: mockFirebase)

        let result = presenter.getFirebaseRemoteConfigLong(key: "count")
        XCTAssertEqual(result, 42)
    }

    func testFirebaseQueriesNilReturnsNil() {
        let presenter = makePresenter(firebaseQuery: nil)

        XCTAssertNil(presenter.getFirebaseRemoteConfigString(key: "any"))
        XCTAssertNil(presenter.getFirebaseRemoteConfigBoolean(key: "any"))
        XCTAssertNil(presenter.getFirebaseRemoteConfigDouble(key: "any"))
        XCTAssertNil(presenter.getFirebaseRemoteConfigLong(key: "any"))
    }

    // MARK: - Session Tags (enabled)

    func testSetSessionTagEnabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: true, noctuaInternal: mockNoctuaInternal)
        presenter.setSessionTag(tag: "tag-1")
        XCTAssertEqual(mockNoctuaInternal.sessionTag, "tag-1")
    }

    func testGetSessionTagEnabled() {
        mockNoctuaInternal.sessionTag = "stored-tag"
        let presenter = makePresenter(nativeInternalTrackerEnabled: true, noctuaInternal: mockNoctuaInternal)

        let result = presenter.getSessionTag()
        XCTAssertEqual(result, "stored-tag")
    }

    func testSetSessionTagDisabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: false, noctuaInternal: mockNoctuaInternal)
        presenter.setSessionTag(tag: "tag-1")
        XCTAssertNil(mockNoctuaInternal.sessionTag)
        XCTAssertTrue(logger.debugMessages.contains("nativeInternalTrackerEnabled is not enabled"))
    }

    func testGetSessionTagDisabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: false, noctuaInternal: mockNoctuaInternal)
        let result = presenter.getSessionTag()
        XCTAssertEqual(result, "")
        XCTAssertTrue(logger.debugMessages.contains("nativeInternalTrackerEnabled is not enabled"))
    }

    // MARK: - Experiments (enabled)

    func testSetExperimentEnabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: true, noctuaInternal: mockNoctuaInternal)
        presenter.setExperiment(experiment: "exp-A")
        XCTAssertEqual(mockNoctuaInternal.experiment, "exp-A")
    }

    func testGetExperimentEnabled() {
        mockNoctuaInternal.experiment = "exp-B"
        let presenter = makePresenter(nativeInternalTrackerEnabled: true, noctuaInternal: mockNoctuaInternal)
        XCTAssertEqual(presenter.getExperiment(), "exp-B")
    }

    func testSetExperimentDisabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: false, noctuaInternal: mockNoctuaInternal)
        presenter.setExperiment(experiment: "exp-A")
        XCTAssertNil(mockNoctuaInternal.experiment)
    }

    func testGetExperimentDisabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: false, noctuaInternal: mockNoctuaInternal)
        XCTAssertEqual(presenter.getExperiment(), "")
    }

    // MARK: - General Experiments

    func testSetGeneralExperimentEnabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: true, noctuaInternal: mockNoctuaInternal)
        presenter.setGeneralExperiment(experiment: "gen-exp-1")
        XCTAssertEqual(mockNoctuaInternal.generalExperiments["default"], "gen-exp-1")
    }

    func testGetGeneralExperimentEnabled() {
        mockNoctuaInternal.generalExperiments["myKey"] = "myValue"
        let presenter = makePresenter(nativeInternalTrackerEnabled: true, noctuaInternal: mockNoctuaInternal)
        XCTAssertEqual(presenter.getGeneralExperiment(experimentKey: "myKey"), "myValue")
    }

    func testSetGeneralExperimentDisabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: false, noctuaInternal: mockNoctuaInternal)
        presenter.setGeneralExperiment(experiment: "gen-exp")
        XCTAssertTrue(mockNoctuaInternal.generalExperiments.isEmpty)
    }

    func testGetGeneralExperimentDisabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: false, noctuaInternal: mockNoctuaInternal)
        XCTAssertEqual(presenter.getGeneralExperiment(experimentKey: "any"), "")
    }

    // MARK: - Session Extra Params

    func testSetSessionExtraParamsEnabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: true, noctuaInternal: mockNoctuaInternal)
        presenter.setSessionExtraParams(payload: ["key": "value"])
        XCTAssertEqual(mockNoctuaInternal.sessionExtraParams?["key"] as? String, "value")
    }

    func testSetSessionExtraParamsDisabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: false, noctuaInternal: mockNoctuaInternal)
        presenter.setSessionExtraParams(payload: ["key": "value"])
        XCTAssertNil(mockNoctuaInternal.sessionExtraParams)
    }

    // MARK: - Events (no guard check - always delegated)

    func testSaveEvents() {
        let presenter = makePresenter(noctuaInternal: mockNoctuaInternal)
        presenter.saveEvents(jsonString: "[{\"event\":\"test\"}]")
        XCTAssertEqual(mockNoctuaInternal.savedEvents, "[{\"event\":\"test\"}]")
    }

    func testGetEvents() {
        mockNoctuaInternal.externalEventsToReturn = ["event1", "event2"]
        let presenter = makePresenter(noctuaInternal: mockNoctuaInternal)
        let expectation = XCTestExpectation(description: "get events")

        presenter.getEvents { events in
            XCTAssertEqual(events, ["event1", "event2"])
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDeleteEvents() {
        let presenter = makePresenter(noctuaInternal: mockNoctuaInternal)
        presenter.deleteEvents()
        XCTAssertTrue(mockNoctuaInternal.deleteExternalEventsCalled)
    }

    // MARK: - Per-Row Events

    func testInsertEvent() {
        let presenter = makePresenter(noctuaInternal: mockNoctuaInternal)
        presenter.insertEvent(eventJson: "{\"type\":\"click\"}")
        XCTAssertEqual(mockNoctuaInternal.insertedEvents, ["{\"type\":\"click\"}"])
    }

    func testGetEventsBatch() {
        mockNoctuaInternal.eventBatchResult = "[{\"id\":1}]"
        let presenter = makePresenter(noctuaInternal: mockNoctuaInternal)
        let expectation = XCTestExpectation(description: "get batch")

        presenter.getEventsBatch(limit: 10, offset: 0) { result in
            XCTAssertEqual(result, "[{\"id\":1}]")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDeleteEventsByIds() {
        let presenter = makePresenter(noctuaInternal: mockNoctuaInternal)
        let expectation = XCTestExpectation(description: "delete events")

        presenter.deleteEventsByIds(idsJson: "[1,2,3]") { count in
            XCTAssertEqual(count, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockNoctuaInternal.deletedEventIds, ["[1,2,3]"])
    }

    func testGetEventCount() {
        mockNoctuaInternal.eventCount = 42
        let presenter = makePresenter(noctuaInternal: mockNoctuaInternal)
        let expectation = XCTestExpectation(description: "event count")

        presenter.getEventCount { count in
            XCTAssertEqual(count, 42)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Attribution

    func testGetAdjustCurrentAttributionWithAdjust() {
        mockAdjust.attributionToReturn = ["network": "facebook", "campaign": "summer"]
        let presenter = makePresenter(adjustSpecific: mockAdjust)
        let expectation = XCTestExpectation(description: "attribution")

        presenter.getAdjustCurrentAttribution { result in
            XCTAssertEqual(result["network"] as? String, "facebook")
            XCTAssertEqual(result["campaign"] as? String, "summer")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetAdjustCurrentAttributionNilAdjust() {
        let presenter = makePresenter(adjustSpecific: nil)
        let expectation = XCTestExpectation(description: "attribution nil")

        presenter.getAdjustCurrentAttribution { result in
            XCTAssertTrue(result.isEmpty)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
