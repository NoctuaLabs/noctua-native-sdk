package com.noctuagames.sdk.inspector

import android.os.Build
import android.os.Process
import android.util.Log
import com.noctuagames.sdk.utils.NoctuaLog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * Tails this process's own logcat stream for Firebase Analytics and Facebook
 * SDK verbose log lines, then translates matches into [NoctuaTrackerEventPhase]
 * transitions on the [NoctuaInspectorBus].
 *
 * Own-process reads (`--pid=<self>`) are permitted on API 31+ without the
 * signature-level READ_LOGS permission. On older API levels, `logcat -d` may
 * still return this process's own lines since self-reads were never restricted
 * in the same way — we still run but note in the log.
 *
 * Log string formats are NOT API contracts. Tested against firebase-analytics
 * 22.x and facebook-android-sdk 17.x. If a future SDK version renames log tags
 * the Inspector will show Queued rows only until this tailer is updated.
 */
object LogTailer {

    private const val TAG = "NoctuaLogTailer"
    private const val POLL_INTERVAL_MS = 500L
    private const val PENDING_TIMEOUT_MS = 30_000L

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var job: Job? = null
    private var lastEpochMs: Long = 0L

    // pending dispatches — `"<provider>:<eventName>"` → list of queued-at timestamps
    private val pendingLock = Any()
    private val pending: HashMap<String, ArrayDeque<Long>> = HashMap()

    // Log patterns
    private val firebaseLoggingEventRegex =
        Regex("""[Ll]ogging event(?: \(FE\))?: ([A-Za-z_][A-Za-z0-9_]*)""")
    private val firebaseUploadingRegex = Regex("""[Uu]ploading data""")
    private val firebaseSuccessfulUploadRegex = Regex("""[Ss]uccessful upload""")
    // FBSDK Android logs event recording in a few formats depending on version:
    //   "Event raw JSON: {"_eventName":"fb_login", ...}"                           (AppEventsLoggerImpl.kt)
    //   "Recording event @ <ts>: { "_eventName" = "fb_login"; ... }"               (NSLog-style ported)
    //   "'fb_login' (custom) tracked: [...]"                                       (Swift-debug style)
    // Match all three so newer / older SDKs both resolve.
    private val facebookRawJsonRegex =
        Regex(""""_eventName"\s*[:=]\s*"([^"]+)"""")
    private val facebookSwiftTrackedRegex =
        Regex("""'([A-Za-z_][A-Za-z0-9_]*)'\s*\(custom\)\s*tracked""")
    private val facebookFlushSuccessRegex = Regex("""Flush result: SUCCESS|[Ff]lushed.*Result:\s*Success""")
    private val facebookFlushErrorRegex = Regex("""Flush result: SERVER_ERROR|[Ff]lushed.*Result:\s*SERVER_ERROR""")

    // Adjust: SDK emits verbose lines tagged `Adjust` on logcat. The native
    // `[Adjust]d:` prefix shown on iOS NSLog is unreadable from Unity, so
    // we rely on Android's logcat. Relevant format:
    //   "Got JSON response with message: Event tracked 'xyz'"
    //   "Event failure callback called!"
    // The Adjust event callback token matches the "callbackId" in our
    // AdjustService.eventMap — if the game mapped event name → token, we
    // can't reverse the mapping here, so pending correlation is best-effort:
    // mark ALL in-flight Adjust events as Acknowledged on each success line,
    // mirroring how the Firebase "Successful upload" broadcast works.
    private val adjustEventTrackedRegex = Regex("""Event tracked '([^']+)'""")
    private val adjustEventFailureRegex = Regex("""Event failure callback called""")

    /** Called by NoctuaPresenter before forwarding to Firebase/Facebook. */
    @JvmStatic
    fun registerPending(provider: String, eventName: String) {
        val key = key(provider, eventName)
        val ts = System.currentTimeMillis()
        synchronized(pendingLock) {
            pending.getOrPut(key) { ArrayDeque() }.addLast(ts)
        }
    }

    @JvmStatic
    fun start() {
        if (job?.isActive == true) return
        lastEpochMs = System.currentTimeMillis()
        job = scope.launch {
            NoctuaLog.i(TAG, "Log tailer started (API=${Build.VERSION.SDK_INT}, pid=${Process.myPid()})")
            while (isActive) {
                try {
                    if (NoctuaInspectorBus.isEnabled()) {
                        pollOnce()
                        pruneStalePending()
                    }
                } catch (t: Throwable) {
                    NoctuaLog.w(TAG, "Tailer iteration failed: ${t.message}")
                }
                delay(POLL_INTERVAL_MS)
            }
        }
    }

    @JvmStatic
    fun stop() {
        scope.coroutineContext.cancelChildren()
        job = null
        synchronized(pendingLock) { pending.clear() }
    }

    // MARK: - Internals

    private fun pollOnce() {
        // Own-process only. Tag filters keep output small; `*:S` silences others.
        val cmd = arrayOf(
            "logcat", "-d", "-v", "threadtime",
            "--pid=${Process.myPid()}",
            "Adjust:V",
            "FA:V", "FA-SVC:V",
            "FacebookSDK.AppEvents:V",
            "FacebookSDK.AppEventsManager:V",
            "*:S"
        )
        val process = try {
            Runtime.getRuntime().exec(cmd)
        } catch (t: Throwable) {
            NoctuaLog.w(TAG, "logcat exec failed: ${t.message}")
            return
        }
        BufferedReader(InputStreamReader(process.inputStream)).use { reader ->
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                val entry = line ?: continue
                processLine(entry)
            }
        }
        // Clear buffer between polls so we don't reprocess the same lines.
        try {
            Runtime.getRuntime().exec("logcat -c").waitFor()
        } catch (_: Throwable) { /* best-effort */ }
    }

    /** Visible for testing. */
    @JvmStatic
    internal fun processLine(line: String) {
        // Firebase Analytics tag — `FA` / `FA-SVC` regardless of logcat format.
        // Matches `threadtime` (` FA:`), `brief` (`/FA:`), or `raw` (`FA:`).
        if (line.contains(" FA:") || line.contains(" FA-SVC:") ||
            line.contains("/FA:") || line.contains("/FA-SVC:") ||
            line.startsWith("FA:") || line.startsWith("FA-SVC:")
        ) {
            val loggingMatch = firebaseLoggingEventRegex.find(line)
            if (loggingMatch != null) {
                val name = loggingMatch.groupValues[1]
                if (consumePending("Firebase", name)) {
                    NoctuaInspectorBus.emit("Firebase", name, phase = NoctuaTrackerEventPhase.EMITTED)
                }
                return
            }
            if (firebaseUploadingRegex.containsMatchIn(line)) {
                broadcast("Firebase", NoctuaTrackerEventPhase.UPLOADING)
                return
            }
            if (firebaseSuccessfulUploadRegex.containsMatchIn(line)) {
                broadcast("Firebase", NoctuaTrackerEventPhase.ACKNOWLEDGED)
                clearProvider("Firebase")
                return
            }
        }

        // Facebook SDK — tag `FacebookSDK.AppEvents*` on Android SDK,
        // OR the newer Swift-debug "(custom) tracked" line surfaced by
        // ported code; OR the NSLog-style "Recording event" dump. Accept
        // any of these because the underlying `_eventName` extraction still
        // works with the shared regexes.
        if (line.contains("FacebookSDK.AppEvents") ||
            line.contains("FBSDKLog:") ||
            line.contains("FBSDKAppEvents") ||
            line.contains("(custom) tracked")
        ) {
            val json = facebookRawJsonRegex.find(line)
            if (json != null) {
                val name = json.groupValues[1]
                if (consumePending("Facebook", name)) {
                    NoctuaInspectorBus.emit("Facebook", name, phase = NoctuaTrackerEventPhase.EMITTED)
                }
                return
            }
            val swift = facebookSwiftTrackedRegex.find(line)
            if (swift != null) {
                val name = swift.groupValues[1]
                if (consumePending("Facebook", name)) {
                    NoctuaInspectorBus.emit("Facebook", name, phase = NoctuaTrackerEventPhase.EMITTED)
                }
                return
            }
            if (facebookFlushSuccessRegex.containsMatchIn(line)) {
                broadcast("Facebook", NoctuaTrackerEventPhase.ACKNOWLEDGED)
                clearProvider("Facebook")
                return
            }
            if (facebookFlushErrorRegex.containsMatchIn(line)) {
                broadcast("Facebook", NoctuaTrackerEventPhase.FAILED)
                clearProvider("Facebook")
                return
            }
        }

        // Adjust tag (exact match — Adjust's own Log.d uses `TAG = "Adjust"`).
        if (line.contains(" Adjust:") ||
            line.contains("/Adjust:") ||
            line.startsWith("Adjust:")
        ) {
            val tracked = adjustEventTrackedRegex.find(line)
            if (tracked != null) {
                // Adjust logs the callback TOKEN (e.g. "1qhqus"), not the
                // game-facing event name — broadcast Acknowledged to every
                // pending Adjust emission and attach the parsed token as
                // extraParams so the Inspector row shows both name+token.
                val token = tracked.groupValues[1]
                broadcast(
                    "Adjust",
                    NoctuaTrackerEventPhase.ACKNOWLEDGED,
                    extraParams = mapOf("adjustToken" to token)
                )
                clearProvider("Adjust")
                return
            }
            if (adjustEventFailureRegex.containsMatchIn(line)) {
                broadcast("Adjust", NoctuaTrackerEventPhase.FAILED)
                clearProvider("Adjust")
                return
            }
        }
    }

    private fun key(provider: String, eventName: String): String = "$provider:$eventName"

    private fun consumePending(provider: String, eventName: String): Boolean {
        val key = key(provider, eventName)
        synchronized(pendingLock) {
            val q = pending[key] ?: return false
            if (q.isEmpty()) return false
            q.removeFirst()
            if (q.isEmpty()) pending.remove(key)
            return true
        }
    }

    private fun broadcast(
        provider: String,
        phase: NoctuaTrackerEventPhase,
        extraParams: Map<String, Any?> = emptyMap()
    ) {
        val snapshot: List<String> = synchronized(pendingLock) {
            pending.keys.filter { it.startsWith("$provider:") }.toList()
        }
        for (k in snapshot) {
            val eventName = k.substringAfter("$provider:")
            NoctuaInspectorBus.emit(provider, eventName, extraParams = extraParams, phase = phase)
        }
    }

    private fun clearProvider(provider: String) {
        synchronized(pendingLock) {
            pending.keys.filter { it.startsWith("$provider:") }.forEach { pending.remove(it) }
        }
    }

    private fun pruneStalePending() {
        val cutoff = System.currentTimeMillis() - PENDING_TIMEOUT_MS
        val expired = mutableListOf<Pair<String, Int>>()
        synchronized(pendingLock) {
            val it = pending.entries.iterator()
            while (it.hasNext()) {
                val e = it.next()
                val q = e.value
                var dropped = 0
                while (q.isNotEmpty() && q.first() < cutoff) {
                    q.removeFirst()
                    dropped++
                }
                if (dropped > 0) expired.add(e.key to dropped)
                if (q.isEmpty()) it.remove()
            }
        }
        for ((key, count) in expired) {
            val parts = key.split(":", limit = 2)
            if (parts.size != 2) continue
            repeat(count) {
                NoctuaInspectorBus.emit(parts[0], parts[1], phase = NoctuaTrackerEventPhase.TIMED_OUT)
            }
        }
    }

    // Testing seams
    internal fun _testReset() {
        synchronized(pendingLock) { pending.clear() }
    }

    internal fun _testPendingCount(provider: String, eventName: String): Int {
        synchronized(pendingLock) {
            return pending[key(provider, eventName)]?.size ?: 0
        }
    }
}
