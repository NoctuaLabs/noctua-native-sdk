package com.noctuagames.sdk.services

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.toBitmap
import com.noctuagames.sdk.R
import com.noctuagames.sdk.utils.NoctuaLog

/**
 * Shows a system notification for a push that arrives while the app is in the foreground.
 *
 * FCM only puts "notification" messages in the tray when the app is in the background; in the
 * foreground it hands them to [NoctuaFirebaseMessagingService.onMessageReceived] and shows nothing.
 * This mirrors the background behaviour (and the iOS foreground banner), using the same channel,
 * icon and tap intent extras FCM uses, so a tap is reported as `push_notification_opened`.
 */
object NoctuaNotificationDisplayer {
    private val TAG = this::class.simpleName

    const val FALLBACK_CHANNEL_ID = "fcm_fallback_notification_channel"
    private const val FALLBACK_CHANNEL_NAME = "Miscellaneous"
    private const val META_DEFAULT_CHANNEL = "com.google.firebase.messaging.default_notification_channel_id"
    private const val META_DEFAULT_ICON = "com.google.firebase.messaging.default_notification_icon"

    /** Posts the notification. Returns false when it could not be shown (no permission, no launcher). */
    fun show(
        context: Context,
        messageId: String?,
        title: String?,
        body: String?,
        channelId: String?,
        data: Map<String, String>,
    ): Boolean {
        // Android 13+ requires the runtime POST_NOTIFICATIONS grant (requested at Noctua.init).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            NoctuaLog.d(TAG, "POST_NOTIFICATIONS not granted; foreground push not shown")
            return false
        }

        val notificationManager = NotificationManagerCompat.from(context)
        if (!notificationManager.areNotificationsEnabled()) {
            NoctuaLog.d(TAG, "Notifications disabled; foreground push not shown")
            return false
        }

        val tapIntent = buildTapIntent(context, messageId, title, body, data) ?: run {
            NoctuaLog.w(TAG, "No launcher activity; foreground push not shown")
            return false
        }

        val notificationId = (messageId ?: System.currentTimeMillis().toString()).hashCode()
        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, resolveChannel(context, channelId))
            .setSmallIcon(resolveSmallIcon(context))
            .setLargeIcon(loadAppIcon(context))
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .build()

        return try {
            notificationManager.notify(notificationId, notification)
            true
        } catch (e: SecurityException) {
            NoctuaLog.w(TAG, "Foreground push not shown: ${e.message}")
            false
        }
    }

    /**
     * Launcher intent carrying the same extras as an FCM tray-notification tap, so the host's
     * existing launch-intent tap detection handles both identically.
     */
    fun buildTapIntent(
        context: Context,
        messageId: String?,
        title: String?,
        body: String?,
        data: Map<String, String>,
    ): Intent? {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        data.forEach { (key, value) -> intent.putExtra(key, value) }
        if (!messageId.isNullOrEmpty()) intent.putExtra(NoctuaPushBridge.EXTRA_MESSAGE_ID, messageId)
        if (title != null) intent.putExtra(NoctuaPushBridge.EXTRA_TITLE, title)
        if (body != null) intent.putExtra(NoctuaPushBridge.EXTRA_BODY, body)
        return intent
    }

    private fun resolveChannel(context: Context, requested: String?): String {
        val channelId = requested?.takeIf { it.isNotEmpty() }
            ?: readMetaString(context, META_DEFAULT_CHANNEL)
            ?: FALLBACK_CHANNEL_ID

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (manager != null && manager.getNotificationChannel(channelId) == null) {
                manager.createNotificationChannel(
                    NotificationChannel(channelId, FALLBACK_CHANNEL_NAME, NotificationManager.IMPORTANCE_DEFAULT)
                )
            }
        }
        return channelId
    }

    // Small icons are drawn from the alpha channel only, so never fall back to the
    // full-colour launcher icon (it renders as a white square).
    fun resolveSmallIcon(context: Context): Int {
        val metaIcon = readMetaData(context)?.getInt(META_DEFAULT_ICON, 0) ?: 0
        return if (metaIcon != 0) metaIcon else R.drawable.noctua_ic_notification
    }

    // The colourful app icon goes in the large-icon slot so the notification stays branded.
    private fun loadAppIcon(context: Context): Bitmap? = try {
        context.packageManager.getApplicationIcon(context.packageName).toBitmap()
    } catch (e: Exception) {
        NoctuaLog.w(TAG, "App icon unavailable for notification: ${e.message}")
        null
    }

    private fun readMetaString(context: Context, key: String): String? =
        readMetaData(context)?.getString(key)?.takeIf { it.isNotEmpty() }

    private fun readMetaData(context: Context) = try {
        context.packageManager
            .getApplicationInfo(context.packageName, PackageManager.GET_META_DATA)
            .metaData
    } catch (e: PackageManager.NameNotFoundException) {
        null
    }
}
