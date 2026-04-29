import Foundation

/// Phase of a tracker event as it moves through the dispatch/transmit lifecycle.
/// Integer raw values are stable across the C ABI so Unity / other consumers
/// can bind to the same numbers without re-declaring the enum.
@objc public enum NoctuaTrackerEventPhase: Int32 {
    case queued       = 0
    case sending      = 1
    case emitted      = 2
    case uploading    = 3
    case acknowledged = 4
    case failed       = 5
    case timedOut     = 6
}

/// C-ABI-friendly signature used by the Unity P/Invoke bridge.
///   (provider, eventName, payloadJson, extraParamsJson, phase)
public typealias NoctuaTrackerEmissionCallback =
    (_ provider: String,
     _ eventName: String,
     _ payloadJson: String,
     _ extraParamsJson: String,
     _ phase: NoctuaTrackerEventPhase) -> Void

/// Verbose-log stream callback signature for the Inspector "Logs" tab.
///   (level [2..6 logcat priority], source, tag, message, timestampMillisUtc)
/// Volumes can be high on iOS too (`os_log` is verbose) — the bus filters
/// at the gate before paying serialisation cost.
public typealias NoctuaLogStreamCallback =
    (_ level: Int32,
     _ source: String,
     _ tag: String,
     _ message: String,
     _ timestampMillisUtc: Int64) -> Void

/// Central pub/sub for tracker emissions. Fire-and-forget — never throws,
/// never calls back on its own queue, always dispatches on the callback setter's
/// responsibility to handle threading. Holds a single callback so we don't
/// silently fan out to multiple sinks (matches existing Noctua static-callback
/// patterns in IosPlugin.cs such as `storedFirebaseSessionIdCompletion`).
public final class NoctuaInspectorBus {
    public static let shared = NoctuaInspectorBus()

    private let queue = DispatchQueue(label: "com.noctuagames.sdk.inspector.bus", attributes: .concurrent)
    private var _callback: NoctuaTrackerEmissionCallback?
    private var _enabled: Bool = false

    // Log-stream channel — separate from tracker emissions because volume
    // is orders of magnitude higher (os_log lines vs analytics events).
    // Stays dormant by default; flipped on by the Unity Inspector Logs tab.
    private var _logCallback: NoctuaLogStreamCallback?
    private var _logStreamEnabled: Bool = false

    private init() {}

    /// Installed once at SDK init when `sandboxEnabled == true`.
    /// Safe to call again to replace; safe to call with `nil` to disable.
    public func setCallback(_ callback: NoctuaTrackerEmissionCallback?) {
        queue.async(flags: .barrier) { [weak self] in
            self?._callback = callback
        }
    }

    /// Gate queried by log-tailers and emitters to skip work entirely when off.
    public var isEnabled: Bool {
        get { queue.sync { _enabled } }
    }

    public func setEnabled(_ enabled: Bool) {
        queue.async(flags: .barrier) { [weak self] in
            self?._enabled = enabled
        }
    }

    /// Emits a phase transition. No-op when disabled or no callback registered.
    /// `payload` / `extraParams` are JSON-stringified here so the C-ABI callback
    /// can pass `const char*` without worrying about dictionary marshalling.
    public func emit(provider: String,
                     eventName: String,
                     payload: [String: Any] = [:],
                     extraParams: [String: Any] = [:],
                     phase: NoctuaTrackerEventPhase) {
        let cb: NoctuaTrackerEmissionCallback? = queue.sync {
            guard _enabled else { return nil }
            return _callback
        }
        guard let callback = cb else { return }

        let payloadJson = Self.serialize(payload)
        let extraJson = Self.serialize(extraParams)
        callback(provider, eventName, payloadJson, extraJson, phase)
    }

    // ----- Log-stream channel -----

    public func setLogCallback(_ callback: NoctuaLogStreamCallback?) {
        queue.async(flags: .barrier) { [weak self] in
            self?._logCallback = callback
        }
    }

    public func setLogStreamEnabled(_ enabled: Bool) {
        queue.async(flags: .barrier) { [weak self] in
            self?._logStreamEnabled = enabled
        }
    }

    public var isLogStreamEnabled: Bool {
        get { queue.sync { _logStreamEnabled } }
    }

    /// Emits one log line. No-op when the bus is off, the log channel is
    /// off, or no callback is registered. Cheap enough to call on every
    /// log entry.
    public func emitLog(level: Int32,
                        source: String,
                        tag: String,
                        message: String,
                        timestampMillisUtc: Int64) {
        let cb: NoctuaLogStreamCallback? = queue.sync {
            guard _enabled, _logStreamEnabled else { return nil }
            return _logCallback
        }
        guard let callback = cb else { return }
        callback(level, source, tag, message, timestampMillisUtc)
    }

    private static func serialize(_ dict: [String: Any]) -> String {
        guard !dict.isEmpty,
              JSONSerialization.isValidJSONObject(dict),
              let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
              let str = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return str
    }
}
