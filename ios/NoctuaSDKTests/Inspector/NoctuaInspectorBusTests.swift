import XCTest
@testable import NoctuaSDK

final class NoctuaInspectorBusTests: XCTestCase {

    override func setUp() {
        super.setUp()
        NoctuaInspectorBus.shared.setCallback(nil)
        NoctuaInspectorBus.shared.setEnabled(false)
    }

    override func tearDown() {
        NoctuaInspectorBus.shared.setCallback(nil)
        NoctuaInspectorBus.shared.setEnabled(false)
        super.tearDown()
    }

    func testEmitNoOpWhenDisabled() {
        var called = false
        NoctuaInspectorBus.shared.setCallback { _, _, _, _, _ in called = true }
        // enabled is still false
        NoctuaInspectorBus.shared.emit(provider: "Firebase", eventName: "test", phase: .queued)
        XCTAssertFalse(called, "callback must not fire when bus disabled")
    }

    func testEmitNoOpWithoutCallback() {
        NoctuaInspectorBus.shared.setEnabled(true)
        // No callback — must not crash
        NoctuaInspectorBus.shared.emit(provider: "Firebase", eventName: "test", phase: .queued)
    }

    func testEmitDeliversProviderEventAndPhase() {
        NoctuaInspectorBus.shared.setEnabled(true)

        var captured: (String, String, NoctuaTrackerEventPhase)?
        NoctuaInspectorBus.shared.setCallback { provider, event, _, _, phase in
            captured = (provider, event, phase)
        }

        NoctuaInspectorBus.shared.emit(provider: "Adjust", eventName: "purchase", phase: .acknowledged)

        XCTAssertEqual(captured?.0, "Adjust")
        XCTAssertEqual(captured?.1, "purchase")
        XCTAssertEqual(captured?.2, .acknowledged)
    }

    func testEmitSerializesPayloadToJson() {
        NoctuaInspectorBus.shared.setEnabled(true)

        var payloadJson: String?
        NoctuaInspectorBus.shared.setCallback { _, _, payload, _, _ in payloadJson = payload }

        NoctuaInspectorBus.shared.emit(
            provider: "Firebase",
            eventName: "purchase_completed",
            payload: ["currency": "USD", "value": 4.99],
            phase: .queued
        )

        let json = try? JSONSerialization.jsonObject(with: Data((payloadJson ?? "").utf8)) as? [String: Any]
        XCTAssertEqual(json?["currency"] as? String, "USD")
        XCTAssertEqual(json?["value"] as? Double, 4.99)
    }

    func testEmitHandlesEmptyDicts() {
        NoctuaInspectorBus.shared.setEnabled(true)

        var payload: String?
        var extra: String?
        NoctuaInspectorBus.shared.setCallback { _, _, p, e, _ in
            payload = p; extra = e
        }
        NoctuaInspectorBus.shared.emit(provider: "Mock", eventName: "e", phase: .queued)
        XCTAssertEqual(payload, "{}")
        XCTAssertEqual(extra, "{}")
    }

    func testPhaseRawValuesStable() {
        // These values cross the C ABI; changing them silently would break Unity.
        XCTAssertEqual(NoctuaTrackerEventPhase.queued.rawValue,       0)
        XCTAssertEqual(NoctuaTrackerEventPhase.sending.rawValue,      1)
        XCTAssertEqual(NoctuaTrackerEventPhase.emitted.rawValue,      2)
        XCTAssertEqual(NoctuaTrackerEventPhase.uploading.rawValue,    3)
        XCTAssertEqual(NoctuaTrackerEventPhase.acknowledged.rawValue, 4)
        XCTAssertEqual(NoctuaTrackerEventPhase.failed.rawValue,       5)
        XCTAssertEqual(NoctuaTrackerEventPhase.timedOut.rawValue,     6)
    }
}
