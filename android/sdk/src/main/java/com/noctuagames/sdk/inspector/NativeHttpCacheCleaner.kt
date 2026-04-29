package com.noctuagames.sdk.inspector

import android.content.Context
import android.os.Looper
import android.webkit.WebView
import com.noctuagames.sdk.utils.NoctuaLog
import java.io.File

/**
 * Wipes Android-side HTTP caches — both [WebView] cache and the app's
 * private `cacheDir`. Sandbox-only; called from the Inspector "Memory"
 * tab's "Clear native HTTP cache" action via [NoctuaInspector.clearNativeHttpCache].
 *
 * `WebView.clearCache(true)` is main-thread-only; we hop to the main
 * Looper if invoked from elsewhere. The cacheDir delete is recursive
 * but skips errors quietly — partial wipes are acceptable for a
 * sandbox debug action.
 */
object NativeHttpCacheCleaner {
    private const val TAG = "NoctuaHttpCacheCleaner"

    @JvmStatic
    fun clear(context: Context?) {
        if (context == null) return

        // 1. WebView cache — must run on the main thread.
        runOnMain {
            try {
                // WebView() requires a non-null Context; uses the
                // Application context to avoid leaking activity refs.
                WebView(context.applicationContext).clearCache(true)
            } catch (t: Throwable) {
                NoctuaLog.w(TAG, "WebView.clearCache failed: ${t.message}")
            }
        }

        // 2. App's private cacheDir — wipe everything below it.
        try {
            context.cacheDir?.let(::deleteRecursive)
        } catch (t: Throwable) {
            NoctuaLog.w(TAG, "cacheDir wipe failed: ${t.message}")
        }
    }

    private fun deleteRecursive(file: File) {
        if (!file.exists()) return
        if (file.isDirectory) {
            file.listFiles()?.forEach(::deleteRecursive)
        }
        // Best-effort: ignore failures (e.g. file held open by another
        // process). Subsequent runs will retry.
        file.delete()
    }

    private fun runOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            android.os.Handler(Looper.getMainLooper()).post(block)
        }
    }
}
