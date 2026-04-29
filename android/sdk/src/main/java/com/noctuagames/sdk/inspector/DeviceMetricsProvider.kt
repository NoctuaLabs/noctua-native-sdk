package com.noctuagames.sdk.inspector

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Debug
import android.os.PowerManager

/**
 * Polls Android process + system memory state for the Inspector "Memory"
 * tab. All work is on the calling thread (the Unity main thread polls at
 * 1 Hz from `MemoryMonitor`); calls are non-blocking on every supported
 * API level.
 *
 * Returns raw bytes — UI formatting happens on the Unity side.
 *
 * Thermal status uses [PowerManager.getCurrentThermalStatus] (API 29+);
 * older API levels report [THERMAL_UNKNOWN] since the platform has no
 * cross-vendor signal before Android 10.
 */
object DeviceMetricsProvider {

    /**
     * Plain-old-data class crossing the JNI boundary as five primitives via
     * [snapshot] — Unity binds individual fields rather than the whole
     * object, so this struct only exists for Kotlin/Java callers.
     */
    data class Snapshot(
        val physFootprintBytes: Long,
        val availableBytes: Long,
        val systemTotalBytes: Long,
        val lowMemory: Boolean,
        val thermal: Int,
    ) {
        companion object {
            const val THERMAL_UNKNOWN = -1
            const val THERMAL_NOMINAL = 0
            const val THERMAL_FAIR = 1
            const val THERMAL_SERIOUS = 2
            const val THERMAL_CRITICAL = 3

            @JvmStatic
            fun empty(): Snapshot = Snapshot(-1, -1, -1, false, THERMAL_UNKNOWN)
        }
    }

    /** Caller supplies an `applicationContext` once at SDK init. */
    @JvmStatic
    fun snapshot(context: Context?): Snapshot {
        if (context == null) return Snapshot.empty()
        return try {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                ?: return Snapshot.empty()

            // PSS — proportional set size in KB; convert to bytes.
            val pssBytes: Long = try {
                val mi = Debug.MemoryInfo()
                Debug.getMemoryInfo(mi)
                mi.totalPss.toLong() * 1024L
            } catch (_: Throwable) { -1L }

            // System memory available + total (bytes).
            val systemInfo = ActivityManager.MemoryInfo()
            am.getMemoryInfo(systemInfo)

            val thermal: Int = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
                    val status = pm?.currentThermalStatus ?: -1
                    mapThermal(status)
                } else {
                    Snapshot.THERMAL_UNKNOWN
                }
            } catch (_: Throwable) { Snapshot.THERMAL_UNKNOWN }

            Snapshot(
                physFootprintBytes = pssBytes,
                availableBytes = systemInfo.availMem,
                systemTotalBytes = systemInfo.totalMem,
                lowMemory = systemInfo.lowMemory,
                thermal = thermal,
            )
        } catch (_: Throwable) {
            Snapshot.empty()
        }
    }

    /** Maps Android [PowerManager] thermal codes (0..6) to the SDK's
     *  normalised 0..3 scale. NONE/LIGHT collapse to 0/1; SEVERE+ all roll
     *  up to "critical" (3). */
    private fun mapThermal(status: Int): Int = when (status) {
        PowerManager.THERMAL_STATUS_NONE     -> Snapshot.THERMAL_NOMINAL
        PowerManager.THERMAL_STATUS_LIGHT    -> Snapshot.THERMAL_FAIR
        PowerManager.THERMAL_STATUS_MODERATE -> Snapshot.THERMAL_SERIOUS
        PowerManager.THERMAL_STATUS_SEVERE,
        PowerManager.THERMAL_STATUS_CRITICAL,
        PowerManager.THERMAL_STATUS_EMERGENCY,
        PowerManager.THERMAL_STATUS_SHUTDOWN -> Snapshot.THERMAL_CRITICAL
        else -> Snapshot.THERMAL_UNKNOWN
    }
}
