import Foundation
import Darwin
#if canImport(UIKit)
import UIKit
#endif

/// Polls iOS process + system memory state for the Inspector "Memory"
/// tab. Mirrors `DeviceMetricsProvider.kt` on the Android side.
///
/// All work is synchronous and non-blocking; called on Unity's main
/// thread at 1 Hz from `MemoryMonitor`. Returns raw bytes.
///
/// `phys_footprint` is the same number Xcode shows in the Memory gauge
/// — drawn from `task_vm_info.phys_footprint`. `os_proc_available_memory`
/// (iOS 13+) reports the headroom before the OS jetsams the app.
public enum DeviceMetricsProvider {

    public static let thermalUnknown:  Int32 = -1
    public static let thermalNominal:  Int32 = 0
    public static let thermalFair:     Int32 = 1
    public static let thermalSerious:  Int32 = 2
    public static let thermalCritical: Int32 = 3

    public struct Snapshot {
        public let physFootprintBytes: Int64
        public let availableBytes: Int64
        public let systemTotalBytes: Int64
        public let lowMemory: Bool
        public let thermal: Int32

        public static func empty() -> Snapshot {
            Snapshot(
                physFootprintBytes: -1,
                availableBytes: -1,
                systemTotalBytes: -1,
                lowMemory: false,
                thermal: thermalUnknown
            )
        }
    }

    public static func snapshot() -> Snapshot {
        let phys = readPhysFootprint()
        let avail = readAvailableMemory()
        let total = Int64(ProcessInfo.processInfo.physicalMemory)
        let thermal = readThermalState()
        // iOS doesn't surface a "system low-memory" boolean the same way
        // Android does — we approximate by flagging when we're <10% of
        // available headroom. -1 sentinel means "couldn't read".
        let low: Bool
        if avail >= 0, total > 0 {
            low = Double(avail) < Double(total) * 0.10
        } else {
            low = false
        }
        return Snapshot(
            physFootprintBytes: phys,
            availableBytes: avail,
            systemTotalBytes: total,
            lowMemory: low,
            thermal: thermal
        )
    }

    /// Returns `phys_footprint` from `task_info(TASK_VM_INFO, …)` — same
    /// figure Xcode's Memory gauge displays. `-1` if the syscall fails.
    private static func readPhysFootprint() -> Int64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard kerr == KERN_SUCCESS else { return -1 }
        return Int64(info.phys_footprint)
    }

    /// `os_proc_available_memory()` is iOS 13+. Returns `-1` on older OS
    /// or any unexpected zero (Apple documents 0 = unavailable).
    private static func readAvailableMemory() -> Int64 {
        if #available(iOS 13.0, tvOS 13.0, *) {
            let v = os_proc_available_memory()
            return v <= 0 ? -1 : Int64(v)
        }
        return -1
    }

    /// Maps `ProcessInfo.thermalState` (0..3) to the SDK's normalised
    /// 0..3 scale. Identical numerics — left explicit for safety against
    /// future enum reordering by Apple.
    private static func readThermalState() -> Int32 {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:  return thermalNominal
        case .fair:     return thermalFair
        case .serious:  return thermalSerious
        case .critical: return thermalCritical
        @unknown default: return thermalUnknown
        }
    }
}
