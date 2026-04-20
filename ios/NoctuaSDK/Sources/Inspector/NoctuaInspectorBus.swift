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
