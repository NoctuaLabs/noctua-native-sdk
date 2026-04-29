package com.noctuagames.sdk.inspector

import android.content.Context

/**
 * Public façade for Inspector callback registration.
 *
 * Unity binds to this via `AndroidJavaClass("com.noctuagames.sdk.inspector.NoctuaInspector")`
 * and passes an `AndroidJavaProxy` implementing [TrackerEmissionCallback]
 * or [LogStreamCallback].
 *
 * Safe to call before [com.noctuagames.sdk.Noctua.init] — callbacks are
 * stored and take effect once the presenter enables the bus (when
 * `sandboxEnabled == true`).
 */
object NoctuaInspector {

    /** Application context held weakly via the static reference of an
     *  [Application] subclass — Unity passes this once at init. Used by
     *  [DeviceMetricsProvider]. Reset to null on [reset] for tests. */
    private var appContextRef: Context? = null

    /** Buffer reused for every device-metrics snapshot — saves the GC
     *  churn of allocating a `long[5]` per Unity poll (1Hz). Read on the
     *  Unity main thread only; if other callers need a snapshot they
     *  should avoid this method. */
    private val metricsScratch = LongArray(5)

    @JvmStatic
    fun setTrackerEmissionCallback(callback: TrackerEmissionCallback?) {
        NoctuaInspectorBus.setCallback(callback)
    }

    /** Force-enable or disable the bus. Normally managed by the presenter
     *  based on sandbox config; exposed for tests and diagnostic tooling. */
    @JvmStatic
    fun setEnabled(enabled: Boolean) {
        NoctuaInspectorBus.setEnabled(enabled)
    }

    @JvmStatic
    fun isEnabled(): Boolean = NoctuaInspectorBus.isEnabled()

    // ----- Log-stream channel (Inspector "Logs" tab) -----

    @JvmStatic
    fun setLogStreamCallback(callback: LogStreamCallback?) {
        NoctuaInspectorBus.setLogCallback(callback)
    }

    @JvmStatic
    fun setLogStreamEnabled(enabled: Boolean) {
        NoctuaInspectorBus.setLogStreamEnabled(enabled)
        if (enabled) LogTailer.startAllLogsMode() else LogTailer.stopAllLogsMode()
    }

    @JvmStatic
    fun isLogStreamEnabled(): Boolean = NoctuaInspectorBus.isLogStreamEnabled()

    // ----- Device metrics (Inspector "Memory" tab) -----

    /** Unity hands us its application context via this hook the first time
     *  the Memory tab polls (or earlier, from `Noctua.init`). */
    @JvmStatic
    fun setApplicationContext(context: Context?) {
        appContextRef = context?.applicationContext
    }

    /**
     * Returns five primitives that map onto Unity's
     * `DeviceMetricsSnapshot`:
     *   `[0]` phys_footprint (PSS) bytes, `-1` if unavailable
     *   `[1]` system available bytes
     *   `[2]` system total bytes
     *   `[3]` 1L if low-memory state, 0L otherwise
     *   `[4]` thermal level (-1 unknown, 0 nominal, 1 fair, 2 serious, 3 critical)
     *
     * Unity reads `long[]` cheaply via `AndroidJavaObject`. The buffer is
     * shared across calls — copy fields immediately on the Unity side.
     */
    @JvmStatic
    fun snapshotDeviceMetricsTuple(): LongArray {
        val s = DeviceMetricsProvider.snapshot(appContextRef)
        metricsScratch[0] = s.physFootprintBytes
        metricsScratch[1] = s.availableBytes
        metricsScratch[2] = s.systemTotalBytes
        metricsScratch[3] = if (s.lowMemory) 1L else 0L
        metricsScratch[4] = s.thermal.toLong()
        return metricsScratch
    }

    // ----- Maintenance (Inspector "Memory" tab Action Panel) -----

    /**
     * Wipes the WebView cache and app `cacheDir`. Called from the Unity
     * Inspector behind a confirm dialog. Falls back to no-op if the
     * application context is missing.
     */
    @JvmStatic
    fun clearNativeHttpCache() {
        NativeHttpCacheCleaner.clear(appContextRef)
    }

    /** Test seam — clears all callbacks + context. Not used in production. */
    @JvmStatic
    fun reset() {
        NoctuaInspectorBus.setCallback(null)
        NoctuaInspectorBus.setLogCallback(null)
        NoctuaInspectorBus.setEnabled(false)
        NoctuaInspectorBus.setLogStreamEnabled(false)
        appContextRef = null
    }
}
