import XCTest
@testable import NoctuaSDK

final class NoctuaInspectorBusTests: XCTestCase {

    override func setUp() {
        super.setUp()
        NoctuaInspectorBus.shared.setCallback(nil)
        NoctuaInspectorBus.shared.setEnabled(false)
        NoctuaInspectorBus.shared.setLogCallback(nil)
        NoctuaInspectorBus.shared.setLogStreamEnabled(false)
    }

    override func tearDown() {
        NoctuaInspectorBus.shared.setCallback(nil)
        NoctuaInspectorBus.shared.setEnabled(false)
        NoctuaInspectorBus.shared.setLogCallback(nil)
        NoctuaInspectorBus.shared.setLogStreamEnabled(false)
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

    // ----- Log-stream channel -----

    func testLogStreamDisabledByDefault() {
        XCTAssertFalse(NoctuaInspectorBus.shared.isLogStreamEnabled)
    }

    func testSetLogStreamEnabledTogglesFlag() {
        NoctuaInspectorBus.shared.setLogStreamEnabled(true)
        XCTAssertTrue(NoctuaInspectorBus.shared.isLogStreamEnabled)
        NoctuaInspectorBus.shared.setLogStreamEnabled(false)
        XCTAssertFalse(NoctuaInspectorBus.shared.isLogStreamEnabled)
    }

    func testEmitLogNoOpWhenBusDisabled() {
        var called = false
        NoctuaInspectorBus.shared.setLogCallback { _, _, _, _, _ in called = true }
        NoctuaInspectorBus.shared.setLogStreamEnabled(true)
        // bus itself still disabled (setUp sets enabled = false)
        NoctuaInspectorBus.shared.emitLog(level: 3, source: "os", tag: "t", message: "m", timestampMillisUtc: 1)
        XCTAssertFalse(called, "emitLog must no-op while the bus is disabled")
    }

    func testEmitLogNoOpWhenLogStreamDisabled() {
        var called = false
        NoctuaInspectorBus.shared.setEnabled(true)
        NoctuaInspectorBus.shared.setLogCallback { _, _, _, _, _ in called = true }
        // log stream channel not enabled
        NoctuaInspectorBus.shared.emitLog(level: 3, source: "os", tag: "t", message: "m", timestampMillisUtc: 1)
        XCTAssertFalse(called, "emitLog must no-op while the log-stream channel is off")
    }

    func testEmitLogDeliversWhenBothEnabled() {
        NoctuaInspectorBus.shared.setEnabled(true)
        NoctuaInspectorBus.shared.setLogStreamEnabled(true)

        var captured: (Int32, String, String, String, Int64)?
        NoctuaInspectorBus.shared.setLogCallback { level, source, tag, message, ts in
            captured = (level, source, tag, message, ts)
        }
        NoctuaInspectorBus.shared.emitLog(level: 4, source: "os_log", tag: "Noctua", message: "hello", timestampMillisUtc: 42)

        XCTAssertEqual(captured?.0, 4)
        XCTAssertEqual(captured?.1, "os_log")
        XCTAssertEqual(captured?.2, "Noctua")
        XCTAssertEqual(captured?.3, "hello")
        XCTAssertEqual(captured?.4, 42)

        NoctuaInspectorBus.shared.setLogCallback(nil)
        NoctuaInspectorBus.shared.setLogStreamEnabled(false)
    }
}

final class IOSLoggerTests: XCTestCase {

    func testEnabledLoggerEmitsAllLevelsWithoutCrashing() {
        let logger = IOSLogger(category: "test")
        logger.isEnabled = true
        // os.Logger output isn't introspectable in unit tests; exercising the bodies
        // verifies they don't crash and covers the enabled branches.
        logger.debug("d")
        logger.info("i")
        logger.warning("w")
        logger.error("e")
    }

    func testDisabledLoggerSuppressesNonErrorLevels() {
        let logger = IOSLogger(category: "test")
        logger.isEnabled = false
        // Covers the early-return guard paths for debug/info/warning.
        logger.debug("d")
        logger.info("i")
        logger.warning("w")
        // error() ignores isEnabled and always logs.
        logger.error("e")
    }

    func testIsEnabledDefaultsTrue() {
        XCTAssertTrue(IOSLogger(category: "x").isEnabled)
    }
}
