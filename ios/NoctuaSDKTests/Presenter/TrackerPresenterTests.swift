import XCTest
@testable import NoctuaSDK

class TrackerPresenterTests: XCTestCase {

    var tracker1: MockTrackerService!
    var tracker2: MockTrackerService!
    var noctuaInternal: MockNoctuaInternalService!
    var logger: MockNoctuaLogger!

    override func setUp() {
        super.setUp()
        tracker1 = MockTrackerService()
        tracker2 = MockTrackerService()
        noctuaInternal = MockNoctuaInternalService()
        logger = MockNoctuaLogger()
    }

    private func makePresenter(
        nativeInternalTrackerEnabled: Bool? = nil,
        trackers: [TrackerServiceProtocol]? = nil,
        noctuaInternal: NoctuaInternalServiceProtocol? = nil
    ) -> TrackerPresenter {
        let config = TestConfigFactory.makeConfig(nativeInternalTrackerEnabled: nativeInternalTrackerEnabled)
        return TrackerPresenter(
            config: config,
            trackers: trackers ?? [tracker1, tracker2],
            noctuaInternal: noctuaInternal ?? self.noctuaInternal,
            logger: logger
        )
    }

    // MARK: - trackAdRevenue

    func testTrackAdRevenueValid() {
        let presenter = makePresenter()
        presenter.trackAdRevenue(source: "admob", revenue: 1.5, currency: "USD", extraPayload: ["key": "val"])

        XCTAssertEqual(tracker1.adRevenueCalls.count, 1)
        XCTAssertEqual(tracker1.adRevenueCalls[0].source, "admob")
        XCTAssertEqual(tracker1.adRevenueCalls[0].revenue, 1.5)
        XCTAssertEqual(tracker1.adRevenueCalls[0].currency, "USD")
        XCTAssertEqual(tracker1.adRevenueCalls[0].extraPayload["key"] as? String, "val")

        XCTAssertEqual(tracker2.adRevenueCalls.count, 1)
        XCTAssertEqual(tracker2.adRevenueCalls[0].source, "admob")
    }

    func testTrackAdRevenueEmptySource() {
        let presenter = makePresenter()
        presenter.trackAdRevenue(source: "", revenue: 1.0, currency: "USD", extraPayload: [:])

        XCTAssertEqual(tracker1.adRevenueCalls.count, 0)
        XCTAssertEqual(tracker2.adRevenueCalls.count, 0)
        XCTAssertTrue(logger.errorMessages.contains("source is empty"))
    }

    func testTrackAdRevenueZeroRevenue() {
        let presenter = makePresenter()
        presenter.trackAdRevenue(source: "admob", revenue: 0, currency: "USD", extraPayload: [:])

        XCTAssertEqual(tracker1.adRevenueCalls.count, 0)
        XCTAssertTrue(logger.errorMessages.contains("revenue is negative or zero"))
    }

    func testTrackAdRevenueNegativeRevenue() {
        let presenter = makePresenter()
        presenter.trackAdRevenue(source: "admob", revenue: -1.0, currency: "USD", extraPayload: [:])

        XCTAssertEqual(tracker1.adRevenueCalls.count, 0)
        XCTAssertTrue(logger.errorMessages.contains("revenue is negative or zero"))
    }

    func testTrackAdRevenueEmptyCurrency() {
        let presenter = makePresenter()
        presenter.trackAdRevenue(source: "admob", revenue: 1.0, currency: "", extraPayload: [:])

        XCTAssertEqual(tracker1.adRevenueCalls.count, 0)
        XCTAssertTrue(logger.errorMessages.contains("currency is empty"))
    }

    func testTrackAdRevenueExtraPayloadPassesThrough() {
        let presenter = makePresenter()
        let payload: [String: Any] = ["network": "unity", "placement": "banner"]
        presenter.trackAdRevenue(source: "admob", revenue: 2.0, currency: "EUR", extraPayload: payload)

        XCTAssertEqual(tracker1.adRevenueCalls[0].extraPayload["network"] as? String, "unity")
        XCTAssertEqual(tracker1.adRevenueCalls[0].extraPayload["placement"] as? String, "banner")
    }

    func testTrackAdRevenueNoTrackers() {
        let presenter = makePresenter(trackers: [])
        // Should not crash
        presenter.trackAdRevenue(source: "admob", revenue: 1.0, currency: "USD", extraPayload: [:])
    }

    // MARK: - trackPurchase

    func testTrackPurchaseValid() {
        let presenter = makePresenter()
        presenter.trackPurchase(orderId: "order-1", amount: 9.99, currency: "USD", extraPayload: ["extra": "data"])

        XCTAssertEqual(tracker1.purchaseCalls.count, 1)
        XCTAssertEqual(tracker1.purchaseCalls[0].orderId, "order-1")
        XCTAssertEqual(tracker1.purchaseCalls[0].amount, 9.99)
        XCTAssertEqual(tracker1.purchaseCalls[0].currency, "USD")

        XCTAssertEqual(tracker2.purchaseCalls.count, 1)
    }

    func testTrackPurchaseEmptyOrderId() {
        let presenter = makePresenter()
        presenter.trackPurchase(orderId: "", amount: 1.0, currency: "USD", extraPayload: [:])

        XCTAssertEqual(tracker1.purchaseCalls.count, 0)
        XCTAssertTrue(logger.errorMessages.contains("orderId is empty"))
    }

    func testTrackPurchaseZeroAmount() {
        let presenter = makePresenter()
        presenter.trackPurchase(orderId: "order-1", amount: 0, currency: "USD", extraPayload: [:])

        XCTAssertEqual(tracker1.purchaseCalls.count, 0)
        XCTAssertTrue(logger.errorMessages.contains("amount is negative or zero"))
    }

    func testTrackPurchaseEmptyCurrency() {
        let presenter = makePresenter()
        presenter.trackPurchase(orderId: "order-1", amount: 1.0, currency: "", extraPayload: [:])

        XCTAssertEqual(tracker1.purchaseCalls.count, 0)
        XCTAssertTrue(logger.errorMessages.contains("currency is empty"))
    }

    func testTrackPurchaseExtraPayloadPassesThrough() {
        let presenter = makePresenter()
        presenter.trackPurchase(orderId: "order-1", amount: 5.0, currency: "USD", extraPayload: ["sku": "premium"])

        XCTAssertEqual(tracker1.purchaseCalls[0].extraPayload["sku"] as? String, "premium")
    }

    // MARK: - trackCustomEvent

    func testTrackCustomEventForwardsToTrackers() {
        let presenter = makePresenter()
        presenter.trackCustomEvent("level_up", payload: ["level": 5])

        XCTAssertEqual(tracker1.customEventCalls.count, 1)
        XCTAssertEqual(tracker1.customEventCalls[0].eventName, "level_up")
        XCTAssertEqual(tracker1.customEventCalls[0].payload["level"] as? Int, 5)
        XCTAssertEqual(tracker2.customEventCalls.count, 1)
    }

    func testTrackCustomEventWithNativeInternalEnabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: true)
        presenter.trackCustomEvent("test_event", payload: ["key": "value"])

        XCTAssertEqual(noctuaInternal.trackedCustomEvents.count, 1)
        XCTAssertEqual(noctuaInternal.trackedCustomEvents[0].0, "test_event")
        XCTAssertEqual(noctuaInternal.trackedCustomEvents[0].1["key"] as? String, "value")
    }

    func testTrackCustomEventWithNativeInternalDisabled() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: false)
        presenter.trackCustomEvent("test_event", payload: [:])

        XCTAssertEqual(noctuaInternal.trackedCustomEvents.count, 0)
    }

    func testTrackCustomEventNilNoctuaInternal() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: true, noctuaInternal: nil)
        // Should not crash even with nativeInternalTrackerEnabled = true
        presenter.trackCustomEvent("test_event", payload: [:])

        XCTAssertEqual(tracker1.customEventCalls.count, 1)
    }

    // MARK: - trackCustomEventWithRevenue

    func testTrackCustomEventWithRevenueForwards() {
        let presenter = makePresenter()
        presenter.trackCustomEventWithRevenue("purchase_event", revenue: 4.99, currency: "USD", payload: ["item": "sword"])

        XCTAssertEqual(tracker1.customEventWithRevenueCalls.count, 1)
        XCTAssertEqual(tracker1.customEventWithRevenueCalls[0].eventName, "purchase_event")
        XCTAssertEqual(tracker1.customEventWithRevenueCalls[0].revenue, 4.99)
        XCTAssertEqual(tracker1.customEventWithRevenueCalls[0].currency, "USD")
        XCTAssertEqual(tracker2.customEventWithRevenueCalls.count, 1)
    }

    func testTrackCustomEventWithRevenueDoesNotCallNoctuaInternal() {
        let presenter = makePresenter(nativeInternalTrackerEnabled: true)
        presenter.trackCustomEventWithRevenue("revenue_event", revenue: 1.0, currency: "USD", payload: [:])

        // trackCustomEventWithRevenue does NOT call noctuaInternal (by design, verified from source)
        XCTAssertEqual(noctuaInternal.trackedCustomEvents.count, 0)
    }
}
