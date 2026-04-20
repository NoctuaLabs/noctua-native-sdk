package com.noctuagames.sdk.inspector

/**
 * Public façade for Inspector callback registration.
 *
 * Unity binds to this via `AndroidJavaClass("com.noctuagames.sdk.inspector.NoctuaInspector")`
 * and passes an `AndroidJavaProxy` implementing [TrackerEmissionCallback].
 *
 * Safe to call before [com.noctuagames.sdk.Noctua.init] — the callback is
 * stored and takes effect once the presenter enables the bus (when
 * `sandboxEnabled == true`).
 */
object NoctuaInspector {

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
}
