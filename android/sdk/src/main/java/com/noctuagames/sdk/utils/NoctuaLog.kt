package com.noctuagames.sdk.utils

import android.util.Log

/**
 * Conditional logging wrapper for the Noctua SDK.
 *
 * When [sandboxEnabled] is true (default), all log levels are active.
 * When false, only [e] (error) logs are emitted; all other levels are suppressed.
 */
object NoctuaLog {

    var sandboxEnabled: Boolean = true

    fun d(tag: String?, msg: String) {
        if (sandboxEnabled) Log.d(tag, msg)
    }

    fun i(tag: String?, msg: String) {
        if (sandboxEnabled) Log.i(tag, msg)
    }

    fun w(tag: String?, msg: String) {
        if (sandboxEnabled) Log.w(tag, msg)
    }

    fun w(tag: String?, msg: String, tr: Throwable) {
        if (sandboxEnabled) Log.w(tag, msg, tr)
    }

    fun e(tag: String?, msg: String) {
        Log.e(tag, msg)
    }

    fun e(tag: String?, msg: String, tr: Throwable?) {
        Log.e(tag, msg, tr)
    }
}
