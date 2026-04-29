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

// ===================================================================
// Inspector Logs tab — verbose log stream bridge.
// ===================================================================

/// C-ABI signature for the verbose-log stream callback.
///   level (logcat priority 2..6), source, tag, message, timestampMillisUtc
public typealias NoctuaCLogStreamCallback = @convention(c) (
    Int32,                  // level
    UnsafePointer<CChar>?,  // source
    UnsafePointer<CChar>?,  // tag
    UnsafePointer<CChar>?,  // message
    Int64                   // timestampMillisUtc
) -> Void

@_cdecl("noctuaSetLogStreamCallback")
public func noctuaSetLogStreamCallback(_ cb: NoctuaCLogStreamCallback?) {
    guard let cb = cb else {
        NoctuaInspectorBus.shared.setLogCallback(nil)
        return
    }
    NoctuaInspectorBus.shared.setLogCallback { level, source, tag, message, ts in
        source.withCString { s in
            tag.withCString { t in
                message.withCString { m in
                    cb(level, s, t, m, ts)
                }
            }
        }
    }
}

@_cdecl("noctuaSetLogStreamEnabled")
public func noctuaSetLogStreamEnabled(_ enabled: Int32) {
    let on = enabled != 0
    NoctuaInspectorBus.shared.setLogStreamEnabled(on)
    if on { FirebaseLogTailer.shared.startAllLogsMode() }
    else  { FirebaseLogTailer.shared.stopAllLogsMode() }
}

// ===================================================================
// Inspector Memory tab — device metrics snapshot bridge.
// ===================================================================

/// Five-out-pointer device metrics snapshot — Unity P/Invoke binds to
/// this. Caller must pass non-null pointers; returns 0 on success, -1
/// on any internal failure (out values left untouched in that case).
///
/// We expose primitives rather than a struct so the C calling convention
/// stays trivially predictable across Unity IL2CPP versions.
@_cdecl("noctuaSnapshotDeviceMetrics")
public func noctuaSnapshotDeviceMetrics(
    _ outPhysFootprint: UnsafeMutablePointer<Int64>?,
    _ outAvailable: UnsafeMutablePointer<Int64>?,
    _ outSystemTotal: UnsafeMutablePointer<Int64>?,
    _ outLowMemory: UnsafeMutablePointer<Int32>?,   // 1/0
    _ outThermal: UnsafeMutablePointer<Int32>?
) -> Int32 {
    let s = DeviceMetricsProvider.snapshot()
    outPhysFootprint?.pointee = s.physFootprintBytes
    outAvailable?.pointee = s.availableBytes
    outSystemTotal?.pointee = s.systemTotalBytes
    outLowMemory?.pointee = s.lowMemory ? 1 : 0
    outThermal?.pointee = s.thermal
    return 0
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
