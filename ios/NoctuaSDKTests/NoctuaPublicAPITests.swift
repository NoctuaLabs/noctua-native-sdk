import XCTest
@testable import NoctuaSDK

class NoctuaPublicAPITests: XCTestCase {

    var mockTracker1: MockTrackerService!
    var mockNoctuaInternal: MockNoctuaInternalService!
    var mockStoreKitService: MockStoreKitService!
    var mockAccountRepo: MockAccountRepository!
    var mockAdjust: MockAdjustSpecific!
    var mockFirebase: MockFirebaseQueryService!
    var logger: MockNoctuaLogger!

    override func setUp() {
        super.setUp()
        mockTracker1 = MockTrackerService()
        mockNoctuaInternal = MockNoctuaInternalService()
        mockStoreKitService = MockStoreKitService()
        mockAccountRepo = MockAccountRepository()
        mockAdjust = MockAdjustSpecific()
        mockFirebase = MockFirebaseQueryService()
        logger = MockNoctuaLogger()

        Noctua.resetForTesting()
    }

    override func tearDown() {
        Noctua.resetForTesting()
        super.tearDown()
    }

    private func configureWithPresenters(
        nativeInternalTrackerEnabled: Bool? = nil,
        includeSession: Bool = true
    ) {
        let config = TestConfigFactory.makeConfig(nativeInternalTrackerEnabled: nativeInternalTrackerEnabled)

        let tracker = TrackerPresenter(
            config: config,
            trackers: [mockTracker1],
            noctuaInternal: mockNoctuaInternal,
            logger: logger
        )

        let storeKit = StoreKitPresenter(
            storeKitService: mockStoreKitService,
            logger: logger
        )

        let account = AccountPresenter(
            accountRepo: mockAccountRepo,
            logger: logger
        )

        let session: SessionPresenter? = includeSession ? SessionPresenter(
            config: config,
            adjustSpecific: mockAdjust,
            firebaseQuery: mockFirebase,
            noctuaInternal: mockNoctuaInternal,
            logger: logger
        ) : nil

        Noctua.configureForTesting(
            tracker: tracker,
            storeKit: storeKit,
            account: account,
            session: session
        )
    }

    // MARK: - Tracking delegation

    func testTrackAdRevenueDelegatesToTracker() {
        configureWithPresenters()

        Noctua.trackAdRevenue(source: "admob", revenue: 1.0, currency: "USD")
        XCTAssertEqual(mockTracker1.adRevenueCalls.count, 1)
        XCTAssertEqual(mockTracker1.adRevenueCalls[0].source, "admob")
    }

    func testTrackPurchaseDelegatesToTracker() {
        configureWithPresenters()

        Noctua.trackPurchase(orderId: "order-1", amount: 5.99, currency: "USD")
        XCTAssertEqual(mockTracker1.purchaseCalls.count, 1)
        XCTAssertEqual(mockTracker1.purchaseCalls[0].orderId, "order-1")
    }

    func testTrackCustomEventDelegatesToTracker() {
        configureWithPresenters()

        Noctua.trackCustomEvent("test_event", payload: ["key": "val"])
        XCTAssertEqual(mockTracker1.customEventCalls.count, 1)
        XCTAssertEqual(mockTracker1.customEventCalls[0].eventName, "test_event")
    }

    // MARK: - Account delegation

    func testPutAccountDelegatesToPresenter() {
        configureWithPresenters()

        Noctua.putAccount(gameId: 1, playerId: 100, rawData: "test-data")
        XCTAssertEqual(mockAccountRepo.putCalls.count, 1)
        XCTAssertEqual(mockAccountRepo.putCalls[0].playerId, 100)
    }

    func testGetAllAccountsDelegatesToPresenter() {
        configureWithPresenters()

        mockAccountRepo.accounts = [Account(playerId: 1, gameId: 1, rawData: "x", lastUpdated: 0)]
        let accounts = Noctua.getAllAccounts()
        XCTAssertEqual(accounts.count, 1)
    }

    // MARK: - Session delegation

    func testOnOnlineDelegatesToSession() {
        configureWithPresenters()

        Noctua.onOnline()
        XCTAssertTrue(mockAdjust.onOnlineCalled)
    }

    // MARK: - Attribution

    func testGetAdjustCurrentAttributionNilSession() {
        Noctua.resetForTesting()
        // Don't configure any session
        Noctua.configureForTesting()

        let expectation = XCTestExpectation(description: "attribution")
        Noctua.getAdjustCurrentAttribution { result in
            XCTAssertTrue(result.isEmpty)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testGetAdjustCurrentAttributionWithSession() {
        mockAdjust.attributionToReturn = ["network": "unity"]
        configureWithPresenters()

        let expectation = XCTestExpectation(description: "attribution")
        Noctua.getAdjustCurrentAttribution { result in
            XCTAssertEqual(result["network"] as? String, "unity")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - StoreKit

    func testIsStoreKitReadyNilPresenter() {
        Noctua.resetForTesting()
        XCTAssertFalse(Noctua.isStoreKitReady())
    }

    func testIsStoreKitReadyFalse() {
        configureWithPresenters()
        mockStoreKitService.isReadyReturnValue = false
        XCTAssertFalse(Noctua.isStoreKitReady())
    }

    // MARK: - Reset

    func testResetForTestingClearsState() {
        configureWithPresenters()

        Noctua.resetForTesting()

        // After reset, all presenters are nil → methods become no-ops
        Noctua.trackAdRevenue(source: "admob", revenue: 1.0, currency: "USD")
        XCTAssertEqual(mockTracker1.adRevenueCalls.count, 0)

        XCTAssertEqual(Noctua.getAllAccounts().count, 0)
        XCTAssertFalse(Noctua.isStoreKitReady())
    }

    // MARK: - TrackCustomEventWithRevenue delegation

    func testTrackCustomEventWithRevenueDelegates() {
        configureWithPresenters()

        Noctua.trackCustomEventWithRevenue("revenue_event", revenue: 2.99, currency: "EUR")
        XCTAssertEqual(mockTracker1.customEventWithRevenueCalls.count, 1)
        XCTAssertEqual(mockTracker1.customEventWithRevenueCalls[0].eventName, "revenue_event")
        XCTAssertEqual(mockTracker1.customEventWithRevenueCalls[0].revenue, 2.99)
    }

    // MARK: - More StoreKit delegation

    func testQueryProductDetailsDelegates() {
        configureWithPresenters()

        Noctua.queryProductDetails(productIds: ["prod1", "prod2"])
        XCTAssertEqual(mockStoreKitService.queryProductDetailsCalls.count, 1)
        XCTAssertEqual(mockStoreKitService.queryProductDetailsCalls[0].0, ["prod1", "prod2"])
    }

    func testPurchaseDelegates() {
        configureWithPresenters()

        Noctua.purchase(productId: "com.test.buy")
        XCTAssertEqual(mockStoreKitService.purchaseCalls.count, 1)
        XCTAssertEqual(mockStoreKitService.purchaseCalls[0], "com.test.buy")
    }

    func testQueryPurchasesDelegates() {
        configureWithPresenters()

        Noctua.queryPurchases()
        XCTAssertEqual(mockStoreKitService.queryPurchasesCalls.count, 1)
    }

    func testRestorePurchasesDelegates() {
        configureWithPresenters()

        Noctua.restorePurchases()
        XCTAssertTrue(mockStoreKitService.restorePurchasesCalled)
    }

    func testGetProductPurchaseStatusDelegates() {
        configureWithPresenters()

        Noctua.getProductPurchaseStatus(productId: "com.test.check")
        XCTAssertEqual(mockStoreKitService.getProductPurchaseStatusCalls.count, 1)
    }

    func testCompletePurchaseProcessingDelegates() {
        configureWithPresenters()

        var result: Bool?
        Noctua.completePurchaseProcessing(
            purchaseToken: "token-1",
            consumableType: .consumable,
            verified: true,
            callback: { r in result = r }
        )
        XCTAssertEqual(mockStoreKitService.completePurchaseProcessingCalls.count, 1)
        XCTAssertEqual(result, true)
    }

    func testDisposeStoreKitDelegates() {
        configureWithPresenters()

        Noctua.initializeStoreKit()
        Noctua.disposeStoreKit()
        XCTAssertTrue(mockStoreKitService.disposeCalled)
    }

    func testRegisterProductDelegates() {
        configureWithPresenters()

        Noctua.registerProduct(productId: "com.test.prod", consumableType: .nonConsumable)
        XCTAssertEqual(mockStoreKitService.registeredProducts.count, 1)
    }

    // MARK: - More Account delegation

    func testGetSingleAccountDelegates() {
        configureWithPresenters()

        mockAccountRepo.accounts = [Account(playerId: 5, gameId: 10, rawData: "data", lastUpdated: 0)]
        let result = Noctua.getSingleAccount(gameId: 10, playerId: 5)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["playerId"] as? Int64, 5)
    }

    func testDeleteAccountDelegates() {
        configureWithPresenters()

        Noctua.deleteAccount(gameId: 1, playerId: 100)
        XCTAssertEqual(mockAccountRepo.deleteCalls.count, 1)
    }

    // MARK: - More Session delegation

    func testOnOfflineDelegates() {
        configureWithPresenters()

        Noctua.onOffline()
        XCTAssertTrue(mockAdjust.onOfflineCalled)
    }

    func testGetFirebaseInstallationIDDelegates() {
        configureWithPresenters()

        let expectation = XCTestExpectation(description: "firebase install id")
        Noctua.getFirebaseInstallationID { id in
            XCTAssertEqual(id, "mock-installation-id")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testGetFirebaseSessionIDDelegates() {
        configureWithPresenters()

        let expectation = XCTestExpectation(description: "firebase session id")
        Noctua.getFirebaseSessionID { id in
            XCTAssertEqual(id, "mock-session-id")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testGetFirebaseRemoteConfigStringDelegates() {
        mockFirebase.remoteConfigStrings["key1"] = "value1"
        configureWithPresenters()

        let result = Noctua.getFirebaseRemoteConfigString(key: "key1")
        XCTAssertEqual(result, "value1")
    }

    func testGetFirebaseRemoteConfigBooleanDelegates() {
        mockFirebase.remoteConfigBooleans["flag"] = true
        configureWithPresenters()

        let result = Noctua.getFirebaseRemoteConfigBoolean(key: "flag")
        XCTAssertTrue(result)
    }

    func testGetFirebaseRemoteConfigDoubleDelegates() {
        mockFirebase.remoteConfigDoubles["price"] = 3.14
        configureWithPresenters()

        let result = Noctua.getFirebaseRemoteConfigDouble(key: "price")
        XCTAssertEqual(result, 3.14)
    }

    func testGetFirebaseRemoteConfigLongDelegates() {
        mockFirebase.remoteConfigLongs["count"] = 99
        configureWithPresenters()

        let result = Noctua.getFirebaseRemoteConfigLong(key: "count")
        XCTAssertEqual(result, 99)
    }

    func testSetSessionTagDelegates() {
        configureWithPresenters(nativeInternalTrackerEnabled: true)

        Noctua.setSessionTag(tag: "test-tag")
        XCTAssertEqual(mockNoctuaInternal.sessionTag, "test-tag")
    }

    func testGetSessionTagsDelegates() {
        configureWithPresenters(nativeInternalTrackerEnabled: true)
        mockNoctuaInternal.sessionTag = "my-tag"

        let result = Noctua.getSessionTags()
        XCTAssertEqual(result, "my-tag")
    }

    func testSetExperimentDelegates() {
        configureWithPresenters(nativeInternalTrackerEnabled: true)

        Noctua.setExperiment(experiment: "exp-A")
        XCTAssertEqual(mockNoctuaInternal.experiment, "exp-A")
    }

    func testGetExperimentDelegates() {
        configureWithPresenters(nativeInternalTrackerEnabled: true)
        mockNoctuaInternal.experiment = "exp-B"

        let result = Noctua.getExperiment()
        XCTAssertEqual(result, "exp-B")
    }

    func testSetGeneralExperimentDelegates() {
        configureWithPresenters(nativeInternalTrackerEnabled: true)

        Noctua.setGeneralExperiment(experiment: "gen-exp-1")
        XCTAssertEqual(mockNoctuaInternal.generalExperiments["default"], "gen-exp-1")
    }

    func testGetGeneralExperimentDelegates() {
        configureWithPresenters(nativeInternalTrackerEnabled: true)
        mockNoctuaInternal.generalExperiments["myKey"] = "myValue"

        let result = Noctua.getGeneralExperiment(experimentKey: "myKey")
        XCTAssertEqual(result, "myValue")
    }

    func testSetSessionExtraParamsDelegates() {
        configureWithPresenters(nativeInternalTrackerEnabled: true)

        Noctua.setSessionExtraParams(payload: ["key": "value"])
        XCTAssertEqual(mockNoctuaInternal.sessionExtraParams?["key"] as? String, "value")
    }

    func testSaveEventsDelegates() {
        configureWithPresenters()

        Noctua.saveEvents(jsonString: "[{\"event\":\"test\"}]")
        XCTAssertEqual(mockNoctuaInternal.savedEvents, "[{\"event\":\"test\"}]")
    }

    func testGetEventsDelegates() {
        mockNoctuaInternal.externalEventsToReturn = ["evt1"]
        configureWithPresenters()

        let expectation = XCTestExpectation(description: "get events")
        Noctua.getEvents { events in
            XCTAssertEqual(events, ["evt1"])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testDeleteEventsDelegates() {
        configureWithPresenters()

        Noctua.deleteEvents()
        XCTAssertTrue(mockNoctuaInternal.deleteExternalEventsCalled)
    }

    func testInsertEventDelegates() {
        configureWithPresenters()

        Noctua.insertEvent(eventJson: "{\"type\":\"click\"}")
        XCTAssertEqual(mockNoctuaInternal.insertedEvents, ["{\"type\":\"click\"}"])
    }

    func testGetEventsBatchDelegates() {
        mockNoctuaInternal.eventBatchResult = "[{\"id\":1}]"
        configureWithPresenters()

        let expectation = XCTestExpectation(description: "get batch")
        Noctua.getEventsBatch(limit: 10, offset: 0) { result in
            XCTAssertEqual(result, "[{\"id\":1}]")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testDeleteEventsByIdsDelegates() {
        configureWithPresenters()

        let expectation = XCTestExpectation(description: "delete events")
        Noctua.deleteEventsByIds(idsJson: "[1,2]") { count in
            XCTAssertEqual(count, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testGetEventCountDelegates() {
        mockNoctuaInternal.eventCount = 42
        configureWithPresenters()

        let expectation = XCTestExpectation(description: "event count")
        Noctua.getEventCount { count in
            XCTAssertEqual(count, 42)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - loadConfig with test bundle

    func testLoadConfigFileNotFound() {
        // Using test bundle which doesn't have noctuagg.json
        let testBundle = Bundle(for: type(of: self))
        XCTAssertThrowsError(try loadConfig(bundle: testBundle)) { error in
            guard case ConfigurationError.fileNotFound = error else {
                XCTFail("Expected ConfigurationError.fileNotFound, got \(error)")
                return
            }
        }
    }
}
