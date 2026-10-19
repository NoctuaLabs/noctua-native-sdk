package com.noctuagames.sdk.services

import android.content.Intent
import android.os.Bundle
import com.noctuagames.sdk.utils.NoctuaLog
import org.json.JSONObject

/**
 * Forwards push notifications to the host (e.g. the Unity bridge): messages received by
 * [NoctuaFirebaseMessagingService] and notification taps detected by [NoctuaPushTapTracker].
 *
 * Either can happen before the host registers its listener (cold start), so the most recent
 * payload of each kind is buffered and handed over as soon as a listener is set — same
 * behaviour as the iOS `CustomAppController` buffering.
 *
 * Both payloads use the JSON shape the Unity `NoctuaNotificationPayload.FromJson` parses:
 * `{"notification":{"title","body"}, <data keys at top level>, "google.message_id": id}`.
 */
object NoctuaPushBridge {
    private val TAG = this::class.simpleName

    const val EXTRA_MESSAGE_ID = "google.message_id"
    const val EXTRA_TITLE = "gcm.notification.title"
    const val EXTRA_BODY = "gcm.notification.body"

    private val received = Channel("received")
    private val tapped = Channel("tapped")

    /** Registers the received-push listener; delivers a buffered payload. Null unregisters. */
    fun setReceivedListener(listener: ((String) -> Unit)?) = received.setListener(listener)

    /** Dispatches a received payload to the listener, or buffers it when none is set. */
    fun dispatchReceived(json: String) = received.dispatch(json)

    /** Registers the notification-tap listener; delivers a buffered payload. Null unregisters. */
    fun setTappedListener(listener: ((String) -> Unit)?) = tapped.setListener(listener)

    /** Dispatches a tap payload to the listener, or buffers it when none is set. */
    fun dispatchTapped(json: String) = tapped.dispatch(json)

    fun buildPayloadJson(
        messageId: String?,
        title: String?,
        body: String?,
        data: Map<String, String>,
    ): String {
        val root = JSONObject()
        data.forEach { (key, value) -> root.put(key, value) }

        if (title != null || body != null) {
            root.put("notification", JSONObject().apply {
                put("title", title ?: "")
                put("body", body ?: "")
            })
        }

        if (!messageId.isNullOrEmpty()) {
            root.put(EXTRA_MESSAGE_ID, messageId)
        }

        return root.toString()
    }

    /**
     * Builds the payload from the extras of a notification-tap intent (FCM tray tap or
     * [NoctuaNotificationDisplayer] tap). Google/GCM bookkeeping keys are dropped; data keys
     * are kept. Returns null when the extras are not from a push notification.
     */
    fun buildTapPayloadJson(extras: Bundle?): String? {
        val messageId = extras?.getString(EXTRA_MESSAGE_ID)
        if (extras == null || messageId.isNullOrEmpty()) return null

        val data = extras.keySet()
            .filterNot { it.startsWith("google.") || it.startsWith("gcm.") }
            .associateWith { extras.getString(it) ?: "" }

        return buildPayloadJson(
            messageId = messageId,
            title = extras.getString(EXTRA_TITLE),
            body = extras.getString(EXTRA_BODY),
            data = data,
        )
    }

    /**
     * Returns the tap payload of [intent] and removes its message id, so the same tap is
     * never reported twice (activities are resumed many times with the same intent).
     */
    fun consumeTapIntent(intent: Intent?): String? {
        val json = buildTapPayloadJson(intent?.extras) ?: return null
        intent?.removeExtra(EXTRA_MESSAGE_ID)
        return json
    }

    /** Test-only: clears listeners and buffered state. */
    internal fun reset() {
        received.setListener(null)
        tapped.setListener(null)
    }

    private class Channel(private val name: String) {
        private var listener: ((String) -> Unit)? = null
        private var pending: String? = null

        fun setListener(newListener: ((String) -> Unit)?) {
            val buffered = synchronized(this) {
                listener = newListener
                pending.also { pending = null }
            }
            if (newListener != null && buffered != null) {
                deliver(newListener, buffered)
            }
        }

        fun dispatch(json: String) {
            val current = synchronized(this) {
                listener ?: run {
                    pending = json
                    null
                }
            }
            if (current != null) {
                deliver(current, json)
            }
        }

        private fun deliver(target: (String) -> Unit, json: String) {
            try {
                target(json)
            } catch (e: Exception) {
                NoctuaLog.w(TAG, "Push $name listener failed: ${e.message}")
            }
        }
    }
}
