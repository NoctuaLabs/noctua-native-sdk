import Foundation
import OSLog

/// Tails Firebase Analytics SDK's own verbose log entries via `OSLogStore`
/// so the Inspector can show `emitted` / `uploading` / `acknowledged`
/// transitions for events we forwarded to Firebase — without requiring
/// Xcode console attachment.
///
/// Requires iOS 15+ and `-FIRDebugEnabled` launch arg (auto-injected by the
/// Unity `BuildPostProcessor` when `sandboxEnabled: true`). On earlier iOS,
/// `start()` is a no-op and the Inspector simply never sees the `emitted`
/// upgrade — rows stay at `queued`.
///
/// The log format is NOT a Firebase API contract. Tested against the
/// firebase-ios-sdk 11.x line-patterns:
///   * "Logging event (FE): <name>, parameters: <dict>"   → emitted
///   * "Uploading data. ..."                              → uploading
///   * "Successful upload. ..."                           → acknowledged
public final class FirebaseLogTailer {
    public static let shared = FirebaseLogTailer()

    private let queue = DispatchQueue(label: "com.noctuagames.sdk.inspector.logtailer", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var lastSeenPosition: Date = .distantPast
    private var pending: [String: [Date]] = [:]       // eventName → queued timestamps
    private let pendingLock = NSLock()
    private let pollIntervalMs: Int = 500
    private let pendingTimeoutSec: TimeInterval = 30

    private static let subsystemFilters = [
        "com.google.firebase.analytics",
        "com.google.firebase.measurement",
        "com.google.analytics",
    ]
    private static let loggingEventRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"[Ll]ogging event(?: \(FE\))?: ([A-Za-z_][A-Za-z0-9_]*)"#,
        options: []
    )
    private static let uploadingRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"[Uu]ploading data"#,
        options: []
    )
    private static let successfulUploadRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"[Ss]uccessful upload"#,
        options: []
    )

    private init() {}

    /// Called by TrackerPresenter (via the bus) when a Queued event is fired
    /// so the log-tailer can correlate the next "Logging event: X" line back
    /// to the pending dispatch.
    public func registerPending(eventName: String, at date: Date = Date()) {
        pendingLock.lock(); defer { pendingLock.unlock() }
        pending[eventName, default: []].append(date)
    }

    public func start() {
        guard #available(iOS 15.0, *) else {
            // OSLogStore unavailable — Inspector degrades to Queued-only for Firebase.
            return
        }
        queue.async { [weak self] in
            guard let self = self, self.timer == nil else { return }
            self.lastSeenPosition = Date().addingTimeInterval(-1)
            let t = DispatchSource.makeTimerSource(queue: self.queue)
            t.schedule(deadline: .now() + .milliseconds(self.pollIntervalMs),
                       repeating: .milliseconds(self.pollIntervalMs))
            t.setEventHandler { [weak self] in self?.poll() }
            t.resume()
            self.timer = t
        }
    }

    public func stop() {
        queue.async { [weak self] in
            self?.timer?.cancel()
            self?.timer = nil
        }
    }

    // MARK: - Polling

    @available(iOS 15.0, *)
    private func poll() {
        guard NoctuaInspectorBus.shared.isEnabled else { return }

        let store: OSLogStore
        do {
            store = try OSLogStore(scope: .currentProcessIdentifier)
        } catch {
            return
        }

        let position = store.position(date: lastSeenPosition)
        let entries: [OSLogEntryLog]
        do {
            entries = try store.getEntries(at: position)
                .compactMap { $0 as? OSLogEntryLog }
        } catch {
            return
        }

        var latest = lastSeenPosition
        for entry in entries {
            if entry.date > latest { latest = entry.date }
            if !Self.isFirebaseSubsystem(entry.subsystem) { continue }
            processLine(entry.composedMessage, at: entry.date)
        }
        lastSeenPosition = latest

        pruneStalePending()
    }

    private static func isFirebaseSubsystem(_ subsystem: String) -> Bool {
        for prefix in subsystemFilters where subsystem.hasPrefix(prefix) {
            return true
        }
        return false
    }

    private func processLine(_ line: String, at date: Date) {
        let nsLine = line as NSString
        let fullRange = NSRange(location: 0, length: nsLine.length)

        if let match = Self.loggingEventRegex?.firstMatch(in: line, options: [], range: fullRange),
           match.numberOfRanges > 1
        {
            let name = nsLine.substring(with: match.range(at: 1))
            if consumePending(eventName: name) {
                NoctuaInspectorBus.shared.emit(
                    provider: "Firebase",
                    eventName: name,
                    phase: .emitted
                )
            }
            return
        }

        if Self.uploadingRegex?.firstMatch(in: line, options: [], range: fullRange) != nil {
            broadcastPhase(.uploading)
            return
        }

        if Self.successfulUploadRegex?.firstMatch(in: line, options: [], range: fullRange) != nil {
            broadcastPhase(.acknowledged)
            pendingLock.lock(); pending.removeAll(); pendingLock.unlock()
        }
    }

    private func consumePending(eventName: String) -> Bool {
        pendingLock.lock(); defer { pendingLock.unlock() }
        guard var list = pending[eventName], !list.isEmpty else { return false }
        list.removeFirst()
        if list.isEmpty {
            pending.removeValue(forKey: eventName)
        } else {
            pending[eventName] = list
        }
        return true
    }

    private func broadcastPhase(_ phase: NoctuaTrackerEventPhase) {
        pendingLock.lock()
        let snapshot = pending
        pendingLock.unlock()
        for (name, _) in snapshot {
            NoctuaInspectorBus.shared.emit(provider: "Firebase", eventName: name, phase: phase)
        }
    }

    private func pruneStalePending() {
        let cutoff = Date().addingTimeInterval(-pendingTimeoutSec)
        pendingLock.lock(); defer { pendingLock.unlock() }
        for (name, dates) in pending {
            let fresh = dates.filter { $0 > cutoff }
            let expired = dates.count - fresh.count
            if fresh.isEmpty {
                pending.removeValue(forKey: name)
            } else if expired > 0 {
                pending[name] = fresh
            }
            for _ in 0..<expired {
                NoctuaInspectorBus.shared.emit(provider: "Firebase", eventName: name, phase: .timedOut)
            }
        }
    }

    // MARK: - Testing seams

    #if DEBUG
    func _testProcessLine(_ line: String, at date: Date = Date()) {
        processLine(line, at: date)
    }
    func _testRegisterPending(_ name: String) {
        registerPending(eventName: name)
    }
    func _testPendingCount(for name: String) -> Int {
        pendingLock.lock(); defer { pendingLock.unlock() }
        return pending[name]?.count ?? 0
    }
    func _testReset() {
        pendingLock.lock()
        pending.removeAll()
        pendingLock.unlock()
    }
    #endif
}
