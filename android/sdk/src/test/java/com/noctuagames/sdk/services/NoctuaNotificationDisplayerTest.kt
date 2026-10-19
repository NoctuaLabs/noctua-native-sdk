package com.noctuagames.sdk.services

import android.Manifest
import android.app.Application
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.core.app.NotificationCompat
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * Robolectric tests for [NoctuaNotificationDisplayer] — needs a real NotificationManager.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], application = android.app.Application::class)
class NoctuaNotificationDisplayerTest {

    private lateinit var context: Application
    private lateinit var notificationManager: NotificationManager

    @Before
    fun setUp() {
        context = RuntimeEnvironment.getApplication()
        notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        shadowOf(context).grantPermissions(Manifest.permission.POST_NOTIFICATIONS)
    }

    private fun registerLauncher() {
        val component = ComponentName(context.packageName, "com.example.LauncherActivity")
        val packageManager = shadowOf(context.packageManager)
        packageManager.addActivityIfNotPresent(component)
        packageManager.addIntentFilterForActivity(
            component,
            IntentFilter(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_LAUNCHER) },
        )
    }

    @Test
    fun `buildTapIntent carries the same extras as an FCM tray tap`() {
        registerLauncher()

        val intent = NoctuaNotificationDisplayer.buildTapIntent(
            context, "0:abc", "Sale", "50% off", mapOf("deeplink" to "game://shop"),
        )!!

        assertEquals("0:abc", intent.getStringExtra("google.message_id"))
        assertEquals("Sale", intent.getStringExtra("gcm.notification.title"))
        assertEquals("50% off", intent.getStringExtra("gcm.notification.body"))
        assertEquals("game://shop", intent.getStringExtra("deeplink"))
        assertTrue(intent.flags and Intent.FLAG_ACTIVITY_CLEAR_TOP != 0)
    }

    @Test
    fun `buildTapIntent returns null without a launcher activity`() {
        assertNull(NoctuaNotificationDisplayer.buildTapIntent(context, "0:abc", null, null, emptyMap()))
    }

    @Test
    fun `show posts a notification on the fallback channel`() {
        registerLauncher()

        val shown = NoctuaNotificationDisplayer.show(
            context, "0:abc", "Sale", "50% off", null, mapOf("deeplink" to "game://shop"),
        )

        assertTrue(shown)
        val posted = shadowOf(notificationManager).allNotifications
        assertEquals(1, posted.size)
        val notification = posted.single()
        assertEquals(NoctuaNotificationDisplayer.FALLBACK_CHANNEL_ID, notification.channelId)
        assertEquals("Sale", notification.extras.getString(NotificationCompat.EXTRA_TITLE))
        assertEquals("50% off", notification.extras.getCharSequence(NotificationCompat.EXTRA_TEXT).toString())
        assertNotNull(notification.contentIntent)
        assertNotNull(notificationManager.getNotificationChannel(NoctuaNotificationDisplayer.FALLBACK_CHANNEL_ID))
    }

    @Test
    fun `small icon defaults to the monochrome SDK icon, never the launcher icon`() {
        assertEquals(
            com.noctuagames.sdk.R.drawable.noctua_ic_notification,
            NoctuaNotificationDisplayer.resolveSmallIcon(context),
        )
    }

    @Test
    fun `show posts with the monochrome small icon`() {
        registerLauncher()

        // Robolectric's test app has no real launcher icon, so the large icon (app icon)
        // falls back to none here; it is verified on device.
        val shown = NoctuaNotificationDisplayer.show(context, "0:abc", "t", "b", null, emptyMap())

        assertTrue(shown)
        val notification = shadowOf(notificationManager).allNotifications.single()
        assertEquals(com.noctuagames.sdk.R.drawable.noctua_ic_notification, notification.smallIcon.resId)
    }

    @Test
    fun `show uses the channel requested by the message`() {
        registerLauncher()

        NoctuaNotificationDisplayer.show(context, "0:abc", "t", "b", "promo", emptyMap())

        assertEquals("promo", shadowOf(notificationManager).allNotifications.single().channelId)
    }

    @Test
    fun `show does nothing when notifications are disabled`() {
        registerLauncher()
        shadowOf(notificationManager).setNotificationsEnabled(false)

        val shown = NoctuaNotificationDisplayer.show(context, "0:abc", "t", "b", null, emptyMap())

        assertFalse(shown)
        assertTrue(shadowOf(notificationManager).allNotifications.isEmpty())
    }

    @Test
    fun `show does nothing without POST_NOTIFICATIONS on Android 13+`() {
        registerLauncher()
        shadowOf(context).denyPermissions(Manifest.permission.POST_NOTIFICATIONS)

        val shown = NoctuaNotificationDisplayer.show(context, "0:abc", "t", "b", null, emptyMap())

        assertFalse(shown)
        assertTrue(shadowOf(notificationManager).allNotifications.isEmpty())
    }

    @Test
    fun `show does nothing without a launcher activity`() {
        val shown = NoctuaNotificationDisplayer.show(context, "0:abc", "t", "b", null, emptyMap())

        assertFalse(shown)
        assertTrue(shadowOf(notificationManager).allNotifications.isEmpty())
    }
}
