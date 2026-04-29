package com.noctuagames.sdk.inspector

import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

/**
 * Phase of a tracker event as it moves through the dispatch/transmit lifecycle.
 * Integer values are stable across the JNI/Unity boundary — changing them
 * silently would break Unity bindings.
 */
enum class NoctuaTrackerEventPhase(val raw: Int) {
    QUEUED(0),
    SENDING(1),
    EMITTED(2),
    UPLOADING(3),
    ACKNOWLEDGED(4),
    FAILED(5),
    TIMED_OUT(6);

    companion object {
        @JvmStatic fun fromRaw(raw: Int): NoctuaTrackerEventPhase =
            values().firstOrNull { it.raw == raw } ?: QUEUED
    }
}

/**
 * Stable SAM interface Unity (via AndroidJavaProxy) and native code implement
 * to receive tracker emission phase transitions.
 */
fun interface TrackerEmissionCallback {
    fun onEmission(
        provider: String,
        eventName: String,
        payloadJson: String,
        extraParamsJson: String,
        phase: Int
    )
}

/**
 * Stable SAM interface for the verbose-log stream — Inspector "Logs" tab.
 * Fired on a worker thread; consumers must marshal back to UI as needed.
 *
 * `level` follows logcat priority numbering (Verbose=2, Debug=3, Info=4,
 * Warn=5, Error=6) so untranslated platform priorities slot in directly.
 * `source` identifies the producer ("Android", "Firebase", "Adjust",
 * "Facebook", "Noctua"). `tagOrEmpty` is the logcat tag (may be empty).
 * `timestampMillisUtc` is `System.currentTimeMillis()` at capture.
 */
fun interface LogStreamCallback {
    fun onLogLine(
        level: Int,
        source: String,
        tagOrEmpty: String,
        message: String,
        timestampMillisUtc: Long
    )
}

/**
 * Central pub/sub for tracker emissions. Fire-and-forget, thread-safe, holds
 * a single callback (mirrors static-callback pattern used elsewhere in the SDK).
 *
 * Enabled only when `config.sandboxEnabled == true`; otherwise [emit] is a
 * cheap AtomicBoolean check that exits immediately.
 */
object NoctuaInspectorBus {
    private val enabled = AtomicBoolean(false)
    private val callbackRef = AtomicReference<TrackerEmissionCallback?>(null)

    // Log-stream channel — separate from tracker emissions because volume
    // is orders of magnitude higher (logcat lines vs analytics events).
    // Stays dormant by default; flipped on by the Unity Inspector Logs tab.
    private val logStreamEnabled = AtomicBoolean(false)
    private val logCallbackRef = AtomicReference<LogStreamCallback?>(null)

    @JvmStatic
    fun setCallback(callback: TrackerEmissionCallback?) {
        callbackRef.set(callback)
    }

    @JvmStatic
    fun setEnabled(flag: Boolean) {
        enabled.set(flag)
    }

    @JvmStatic
    fun isEnabled(): Boolean = enabled.get()

    // ----- Log-stream channel -----

    @JvmStatic
    fun setLogCallback(callback: LogStreamCallback?) {
        logCallbackRef.set(callback)
    }

    @JvmStatic
    fun setLogStreamEnabled(flag: Boolean) {
        logStreamEnabled.set(flag)
    }

    @JvmStatic
    fun isLogStreamEnabled(): Boolean = logStreamEnabled.get()

    /** Emits one log line. No-op when the bus is off, the log channel is
     *  off, or no callback is registered. Cheap enough to call on every
     *  logcat line — three atomic reads and an early-exit. */
    @JvmStatic
    fun emitLog(
        level: Int,
        source: String,
        tagOrEmpty: String,
        message: String,
        timestampMillisUtc: Long
    ) {
        if (!enabled.get() || !logStreamEnabled.get()) return
        val cb = logCallbackRef.get() ?: return
        cb.onLogLine(level, source, tagOrEmpty, message, timestampMillisUtc)
    }

    /** Emits a phase transition. No-op when disabled or no callback registered. */
    @JvmStatic
    @JvmOverloads
    fun emit(
        provider: String,
        eventName: String,
        payload: Map<String, Any?> = emptyMap(),
        extraParams: Map<String, Any?> = emptyMap(),
        phase: NoctuaTrackerEventPhase
    ) {
        if (!enabled.get()) return
        val cb = callbackRef.get() ?: return
        cb.onEmission(
            provider,
            eventName,
            serialize(payload),
            serialize(extraParams),
            phase.raw
        )
    }

    /** Minimal JSON serializer — avoids `org.json.JSONObject` so this class
     *  remains portable to pure-JVM unit tests (Android stubs `JSONObject`
     *  in local unit tests). Handles the value shapes the SDK actually emits:
     *  String / Number / Boolean / null / Map / List. Anything else is coerced
     *  via `toString()`. */
    internal fun serialize(map: Map<String, Any?>): String {
        if (map.isEmpty()) return "{}"
        val sb = StringBuilder("{")
        var first = true
        for ((k, v) in map) {
            if (!first) sb.append(',')
            first = false
            appendString(sb, k)
            sb.append(':')
            appendValue(sb, v)
        }
        sb.append('}')
        return sb.toString()
    }

    private fun appendValue(sb: StringBuilder, value: Any?) {
        when (value) {
            null -> sb.append("null")
            is Boolean -> sb.append(value.toString())
            is Number -> {
                val d = value.toDouble()
                if (d.isNaN() || d.isInfinite()) sb.append("null") else sb.append(value.toString())
            }
            is String -> appendString(sb, value)
            is Map<*, *> -> {
                @Suppress("UNCHECKED_CAST")
                sb.append(serialize(value as Map<String, Any?>))
            }
            is Iterable<*> -> {
                sb.append('[')
                var f = true
                for (item in value) {
                    if (!f) sb.append(',')
                    f = false
                    appendValue(sb, item)
                }
                sb.append(']')
            }
            else -> appendString(sb, value.toString())
        }
    }

    private fun appendString(sb: StringBuilder, s: String) {
        sb.append('"')
        for (ch in s) {
            when (ch) {
                '\\' -> sb.append("\\\\")
                '"'  -> sb.append("\\\"")
                '\n' -> sb.append("\\n")
                '\r' -> sb.append("\\r")
                '\t' -> sb.append("\\t")
                '\b' -> sb.append("\\b")
                '\u000C' -> sb.append("\\f")
                else -> if (ch.code < 0x20) sb.append("\\u%04x".format(ch.code)) else sb.append(ch)
            }
        }
        sb.append('"')
    }
}
