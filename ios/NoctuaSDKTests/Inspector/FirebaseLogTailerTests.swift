import XCTest
@testable import NoctuaSDK

final class FirebaseLogTailerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        #if DEBUG
        FirebaseLogTailer.shared._testReset()
        #endif
        NoctuaInspectorBus.shared.setCallback(nil)
        NoctuaInspectorBus.shared.setEnabled(true)
    }

    override func tearDown() {
        #if DEBUG
        FirebaseLogTailer.shared._testReset()
        #endif
        NoctuaInspectorBus.shared.setCallback(nil)
        NoctuaInspectorBus.shared.setEnabled(false)
        super.tearDown()
    }

    func testLoggingEventLineEmitsEmitted() throws {
        #if !DEBUG
        throw XCTSkip("requires DEBUG-only testing seams")
        #else
        var captured: (String, NoctuaTrackerEventPhase)?
        NoctuaInspectorBus.shared.setCallback { _, event, _, _, phase in
            captured = (event, phase)
        }

        FirebaseLogTailer.shared._testRegisterPending("purchase_completed")
        FirebaseLogTailer.shared._testProcessLine(
            "Logging event (FE): purchase_completed, parameters: (\n)"
        )

        XCTAssertEqual(captured?.0, "purchase_completed")
        XCTAssertEqual(captured?.1, .emitted)
        XCTAssertEqual(FirebaseLogTailer.shared._testPendingCount(for: "purchase_completed"), 0,
                       "pending slot must be consumed once matched")
        #endif
    }

    func testLoggingEventWithoutPendingIsIgnored() throws {
        #if !DEBUG
        throw XCTSkip("requires DEBUG-only testing seams")
        #else
        var fired = false
        NoctuaInspectorBus.shared.setCallback { _, _, _, _, _ in fired = true }

        // No registerPending call first.
        FirebaseLogTailer.shared._testProcessLine(
            "Logging event (FE): stray_event, parameters: (\n)"
        )
        XCTAssertFalse(fired, "unmatched events must not spuriously emit")
        #endif
    }

    func testUploadingLineBroadcastsUploading() throws {
        #if !DEBUG
        throw XCTSkip("requires DEBUG-only testing seams")
        #else
        var phases: [NoctuaTrackerEventPhase] = []
        NoctuaInspectorBus.shared.setCallback { _, _, _, _, phase in phases.append(phase) }

        FirebaseLogTailer.shared._testRegisterPending("a")
        FirebaseLogTailer.shared._testRegisterPending("b")
        FirebaseLogTailer.shared._testProcessLine("Uploading data. app=foo, url=bar")

        XCTAssertEqual(phases.filter { $0 == .uploading }.count, 2,
                       "uploading broadcasts to every pending event")
        #endif
    }

    func testSuccessfulUploadClearsPending() throws {
        #if !DEBUG
        throw XCTSkip("requires DEBUG-only testing seams")
        #else
        FirebaseLogTailer.shared._testRegisterPending("a")
        FirebaseLogTailer.shared._testRegisterPending("b")

        FirebaseLogTailer.shared._testProcessLine("Successful upload. 2 events")

        XCTAssertEqual(FirebaseLogTailer.shared._testPendingCount(for: "a"), 0)
        XCTAssertEqual(FirebaseLogTailer.shared._testPendingCount(for: "b"), 0)
        #endif
    }

    func testRegexHandlesAlternateFormat() throws {
        #if !DEBUG
        throw XCTSkip("requires DEBUG-only testing seams")
        #else
        var event: String?
        NoctuaInspectorBus.shared.setCallback { _, name, _, _, _ in event = name }

        FirebaseLogTailer.shared._testRegisterPending("level_up")
        // Some SDK versions omit the "(FE)" suffix
        FirebaseLogTailer.shared._testProcessLine("Logging event: level_up, parameters: {}")

        XCTAssertEqual(event, "level_up")
        #endif
    }
}
