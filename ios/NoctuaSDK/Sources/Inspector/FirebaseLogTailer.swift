import Foundation
import OSLog

/// Tails 3rd-party ad/attribution SDK verbose logs via `OSLogStore` so the
/// Inspector can show `emitted` / `uploading` / `acknowledged` transitions
/// for events we forwarded — without requiring Xcode console attachment.
///
/// Currently covers:
///   * Firebase Analytics   — subsystem `com.google.firebase.analytics`
///     (+ `measurement`, + `analytics`). Requires iOS 15+ and
///     `-FIRDebugEnabled` (auto-injected by Unity BuildPostProcessor in
///     sandbox builds). Pattern: `"Logging event (FE): <name>, ..."`.
///   * Adjust               — subsystem `com.adjust.sdk`. Adjust 4.x+ uses
///     `os_log`. Pattern: `"Got JSON response with message: Event tracked '<token>'"`.
///     The log carries the Adjust CALLBACK TOKEN, not the game-facing event
///     name, so we broadcast `acknowledged` to every pending Adjust row
///     (mirrors how Firebase's "Successful upload" broadcasts).
///
/// Class name kept for backwards compatibility (callers reference
/// `FirebaseLogTailer.shared`); content is provider-agnostic.
public final class FirebaseLogTailer {
    public static let shared = FirebaseLogTailer()

    private let queue = DispatchQueue(label: "com.noctuagames.sdk.inspector.logtailer", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var lastSeenPosition: Date = .distantPast
    // provider → eventName → queued timestamps
    private var pending: [String: [String: [Date]]] = [:]
    private let pendingLock = NSLock()
    private let pollIntervalMs: Int = 500
    private let pendingTimeoutSec: TimeInterval = 30

    private static let firebaseSubsystemFilters = [
        "com.google.firebase.analytics",
        "com.google.firebase.measurement",
        "com.google.analytics",
    ]
    private static let adjustSubsystemFilters = [
        "com.adjust.sdk",
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

    // Adjust's success log comes through ADJLogger as:
    //   "Got JSON response with message: Event tracked 'xyz'"
    // where 'xyz' is the Adjust callback TOKEN (not the event name). Older
    // v4 emits the exact same string via ADJPackageHandler's
    // `responseCallback:`. Adjust v5 emits "Launching success event
    // tracking delegate" instead; match both.
    private static let adjustEventTrackedRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"Event tracked '([^']+)'"#,
        options: []
    )
    private static let adjustEventDelegateRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"[Ll]aunching success event tracking"#,
        options: []
    )
    private static let adjustEventFailureRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"[Ll]aunching failed event tracking|Event failure callback"#,
        options: []
    )

    // Facebook SDK on iOS uses `NSLog(@"FBSDKLog: ...")` which iOS 10+
    // routes through unified logging under the app's DEFAULT subsystem
    // (not `com.facebook.sdk`). We therefore match on message content.
    //
    // Known emission patterns (FBSDK 17.x, verified against user logs):
    //   "FBSDKLog: FBSDKAppEvents: Recording event @ <ts>: { "_eventName" = "X"; ... }"
    //   "FBSDKLog: FBSDKAppEvents: Flushed @ ...: Result: Success"
    //   "FBSDKLog: FBSDKAppEvents: Flushed @ ...: Result: SERVER_ERROR"
    //   "'<eventName>' (custom) tracked: [...]"   (Swift-debug print variant)
    private static let facebookRecordEventRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"FBSDKAppEvents:\s*Recording event.*?"_eventName"\s*=\s*"([^"]+)""#,
        options: [.dotMatchesLineSeparators]
    )
    private static let facebookSwiftTrackedRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"'([A-Za-z_][A-Za-z0-9_]*)'\s*\(custom\)\s*tracked"#,
        options: []
    )
    private static let facebookFlushSuccessRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"FBSDKAppEvents:.*?[Ff]lushed.*?Result:\s*Success"#,
        options: []
    )
    private static let facebookFlushErrorRegex: NSRegularExpression? = try? NSRegularExpression(
        pattern: #"FBSDKAppEvents:.*?[Ff]lushed.*?Result:\s*SERVER_ERROR"#,
        options: []
    )

    private init() {}

    /// Legacy single-provider entry — defaults to Firebase to preserve the
    /// existing call site in TrackerPresenter. Prefer the explicit-provider
    /// overload for anything new.
    public func registerPending(eventName: String, at date: Date = Date()) {
        registerPending(provider: "Firebase", eventName: eventName, at: date)
    }

    /// Called by TrackerPresenter (via the bus) when a Queued event is fired
    /// so the log-tailer can later correlate a provider-specific success line
    /// back to this pending dispatch.
    public func registerPending(provider: String, eventName: String, at date: Date = Date()) {
        pendingLock.lock(); defer { pendingLock.unlock() }
        var perProvider = pending[provider] ?? [:]
        perProvider[eventName, default: []].append(date)
        pending[provider] = perProvider
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
            let msg = entry.composedMessage
            if let provider = Self.providerFor(subsystem: entry.subsystem) {
                processLine(msg, provider: provider, at: entry.date)
            } else if Self.looksLikeFacebook(msg) {
                // FBSDK uses NSLog (subsystem = app default), so we match
                // on the distinctive "FBSDKLog:" prefix instead.
                processLine(msg, provider: "Facebook", at: entry.date)
            }
        }
        lastSeenPosition = latest

        pruneStalePending()
    }

    private static func providerFor(subsystem: String) -> String? {
        for prefix in firebaseSubsystemFilters where subsystem.hasPrefix(prefix) {
            return "Firebase"
        }
        for prefix in adjustSubsystemFilters where subsystem.hasPrefix(prefix) {
            return "Adjust"
        }
        return nil
    }

    private static func looksLikeFacebook(_ msg: String) -> Bool {
        return msg.contains("FBSDKLog:") || msg.contains("FBSDKAppEvents:") ||
               msg.contains("(custom) tracked")
    }

    /// Overload kept for the Obj-C / DEBUG test seam.
    public func _testProcessLine(_ line: String, at date: Date = Date()) {
        processLine(line, provider: "Firebase", at: date)
    }

    private func processLine(_ line: String, provider: String, at date: Date) {
        let nsLine = line as NSString
        let fullRange = NSRange(location: 0, length: nsLine.length)

        if provider == "Firebase" {
            if let match = Self.loggingEventRegex?.firstMatch(in: line, options: [], range: fullRange),
               match.numberOfRanges > 1
            {
                let name = nsLine.substring(with: match.range(at: 1))
                if consumePending(provider: "Firebase", eventName: name) {
                    NoctuaInspectorBus.shared.emit(
                        provider: "Firebase",
                        eventName: name,
                        phase: .emitted
                    )
                }
                return
            }
            if Self.uploadingRegex?.firstMatch(in: line, options: [], range: fullRange) != nil {
                broadcastPhase(.uploading, provider: "Firebase")
                return
            }
            if Self.successfulUploadRegex?.firstMatch(in: line, options: [], range: fullRange) != nil {
                broadcastPhase(.acknowledged, provider: "Firebase")
                clearProvider("Firebase")
            }
            return
        }

        if provider == "Facebook" {
            // "Recording event ..." = SDK queued the event locally.
            // Match both the NSLog dict format and the Swift `print` format
            // the user can see in Xcode. Either way we get the event name.
            if let m = Self.facebookRecordEventRegex?.firstMatch(
                in: line, options: [], range: fullRange),
               m.numberOfRanges > 1 {
                let name = nsLine.substring(with: m.range(at: 1))
                if consumePending(provider: "Facebook", eventName: name) {
                    NoctuaInspectorBus.shared.emit(provider: "Facebook", eventName: name, phase: .emitted)
                }
                return
            }
            if let m = Self.facebookSwiftTrackedRegex?.firstMatch(
                in: line, options: [], range: fullRange),
               m.numberOfRanges > 1 {
                let name = nsLine.substring(with: m.range(at: 1))
                if consumePending(provider: "Facebook", eventName: name) {
                    NoctuaInspectorBus.shared.emit(provider: "Facebook", eventName: name, phase: .emitted)
                }
                return
            }
            if Self.facebookFlushSuccessRegex?.firstMatch(in: line, options: [], range: fullRange) != nil {
                broadcastPhase(.acknowledged, provider: "Facebook")
                clearProvider("Facebook")
                return
            }
            if Self.facebookFlushErrorRegex?.firstMatch(in: line, options: [], range: fullRange) != nil {
                broadcastPhase(.failed, provider: "Facebook")
                clearProvider("Facebook")
            }
            return
        }

        if provider == "Adjust" {
            // Adjust's "Event tracked 'token'" (v4) or "Launching success
            // event tracking delegate" (v5) both mean the server accepted
            // the event. The log carries the callback TOKEN (not the game-
            // facing event name), so we broadcast to every pending Adjust
            // emission and attach the parsed token as extraParams so the
            // Inspector row shows both name and token in its expanded view.
            if let tokenMatch = Self.adjustEventTrackedRegex?.firstMatch(
                in: line, options: [], range: fullRange),
               tokenMatch.numberOfRanges > 1
            {
                let token = nsLine.substring(with: tokenMatch.range(at: 1))
                broadcastPhase(.acknowledged, provider: "Adjust",
                               extraParams: ["adjustToken": token])
                clearProvider("Adjust")
                return
            }
            if Self.adjustEventDelegateRegex?.firstMatch(in: line, options: [], range: fullRange) != nil {
                broadcastPhase(.acknowledged, provider: "Adjust")
                clearProvider("Adjust")
                return
            }
            if Self.adjustEventFailureRegex?.firstMatch(in: line, options: [], range: fullRange) != nil {
                broadcastPhase(.failed, provider: "Adjust")
                clearProvider("Adjust")
            }
            return
        }
    }

    private func consumePending(provider: String, eventName: String) -> Bool {
        pendingLock.lock(); defer { pendingLock.unlock() }
        guard var perProvider = pending[provider],
              var list = perProvider[eventName], !list.isEmpty else { return false }
        list.removeFirst()
        if list.isEmpty {
            perProvider.removeValue(forKey: eventName)
        } else {
            perProvider[eventName] = list
        }
        pending[provider] = perProvider.isEmpty ? nil : perProvider
        return true
    }

    private func broadcastPhase(_ phase: NoctuaTrackerEventPhase,
                                provider: String,
                                extraParams: [String: Any] = [:]) {
        pendingLock.lock()
        let snapshot = pending[provider] ?? [:]
        pendingLock.unlock()
        for (name, _) in snapshot {
            NoctuaInspectorBus.shared.emit(
                provider: provider,
                eventName: name,
                extraParams: extraParams,
                phase: phase
            )
        }
    }

    private func clearProvider(_ provider: String) {
        pendingLock.lock(); defer { pendingLock.unlock() }
        pending.removeValue(forKey: provider)
    }

    private func pruneStalePending() {
        let cutoff = Date().addingTimeInterval(-pendingTimeoutSec)
        var timedOutEmissions: [(String, String)] = []
        pendingLock.lock()
        for (provider, var perProvider) in pending {
            for (name, dates) in perProvider {
                let fresh = dates.filter { $0 > cutoff }
                let expired = dates.count - fresh.count
                if fresh.isEmpty {
                    perProvider.removeValue(forKey: name)
                } else if expired > 0 {
                    perProvider[name] = fresh
                }
                for _ in 0..<expired {
                    timedOutEmissions.append((provider, name))
                }
            }
            pending[provider] = perProvider.isEmpty ? nil : perProvider
        }
        pendingLock.unlock()
        for (provider, name) in timedOutEmissions {
            NoctuaInspectorBus.shared.emit(provider: provider, eventName: name, phase: .timedOut)
        }
    }

    // MARK: - Testing seams

    #if DEBUG
    func _testRegisterPending(_ name: String, provider: String = "Firebase") {
        registerPending(provider: provider, eventName: name)
    }
    func _testPendingCount(for name: String, provider: String = "Firebase") -> Int {
        pendingLock.lock(); defer { pendingLock.unlock() }
        return pending[provider]?[name]?.count ?? 0
    }
    func _testReset() {
        pendingLock.lock()
        pending.removeAll()
        pendingLock.unlock()
    }
    func _testProcessAdjustLine(_ line: String, at date: Date = Date()) {
        processLine(line, provider: "Adjust", at: date)
    }
    #endif
}
