import Foundation

/// C-ABI-compatible function pointer used by the Unity P/Invoke bridge
/// (and any other C/Obj-C caller). Strings are UTF-8 `const char*`;
/// `phase` is the raw value of `NoctuaTrackerEventPhase`.
public typealias NoctuaCTrackerEmissionCallback = @convention(c) (
    UnsafePointer<CChar>?,  // provider
    UnsafePointer<CChar>?,  // eventName
    UnsafePointer<CChar>?,  // payloadJson
    UnsafePointer<CChar>?,  // extraParamsJson
    Int32                   // phase (NoctuaTrackerEventPhase raw)
) -> Void

/// Register the Inspector callback from Unity via `[DllImport("__Internal")]`.
/// Pass `nil` to unregister. Safe to call any time — calls made before
/// `Noctua.initNoctua` will simply no-op until the bus is enabled.
@_cdecl("noctuaSetTrackerEmissionCallback")
public func noctuaSetTrackerEmissionCallback(_ cb: NoctuaCTrackerEmissionCallback?) {
    guard let cb = cb else {
        NoctuaInspectorBus.shared.setCallback(nil)
        return
    }
    NoctuaInspectorBus.shared.setCallback { provider, event, payload, extra, phase in
        provider.withCString { p in
            event.withCString { e in
                payload.withCString { pl in
                    extra.withCString { ex in
                        cb(p, e, pl, ex, phase.rawValue)
                    }
                }
            }
        }
    }
}

/// Escape hatch so host apps can force-enable/disable the bus without
/// re-initialising the SDK (useful for unit tests and the standalone
/// NoctuaInteropTestApp).
@_cdecl("noctuaInspectorSetEnabled")
public func noctuaInspectorSetEnabled(_ enabled: Int32) {
    NoctuaInspectorBus.shared.setEnabled(enabled != 0)
}

/// Obj-C-callable façade for the same controls, for cases where Swift or
/// ObjC callers want a typed API instead of the C-ABI pointer.
@objc public class NoctuaInspector: NSObject {
    @objc public static func setCallback(_ callback: ((String, String, String, String, Int32) -> Void)?) {
        guard let callback = callback else {
            NoctuaInspectorBus.shared.setCallback(nil)
            return
        }
        NoctuaInspectorBus.shared.setCallback { provider, event, payload, extra, phase in
            callback(provider, event, payload, extra, phase.rawValue)
        }
    }

    @objc public static func setEnabled(_ enabled: Bool) {
        NoctuaInspectorBus.shared.setEnabled(enabled)
    }

    @objc public static var isEnabled: Bool {
        return NoctuaInspectorBus.shared.isEnabled
    }
}
