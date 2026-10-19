package com.noctuagames.sdk.services

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Robolectric tests for notification-tap detection ([NoctuaPushTapTracker]) and the tap side of
 * [NoctuaPushBridge].
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], application = android.app.Application::class)
class NoctuaPushTapTrackerTest {

    private val taps = mutableListOf<String>()

    @Before
    fun setUp() {
        NoctuaPushBridge.reset()
        NoctuaPushBridge.setTappedListener { taps.add(it) }
    }

    @After
    fun tearDown() = NoctuaPushBridge.reset()

    private fun tapIntent(messageId: String) = Intent(Intent.ACTION_MAIN).apply {
        putExtra("google.message_id", messageId)
        putExtra("google.sent_time", 1700000000000L)
        putExtra("gcm.notification.title", "Sale")
        putExtra("gcm.notification.body", "50% off")
        putExtra("from", "1234")
        putExtra("deeplink", "game://shop")
    }

    @Test
    fun `buildTapPayloadJson keeps data and message id, drops bookkeeping keys`() {
        val json = JSONObject(NoctuaPushBridge.buildTapPayloadJson(tapIntent("0:a").extras)!!)

        assertEquals("0:a", json.getString("google.message_id"))
        assertEquals("game://shop", json.getString("deeplink"))
        assertEquals("1234", json.getString("from"))
        assertEquals("Sale", json.getJSONObject("notification").getString("title"))
        assertEquals("50% off", json.getJSONObject("notification").getString("body"))
        assertFalse(json.has("google.sent_time"))
        assertFalse(json.has("gcm.notification.title"))
    }

    @Test
    fun `buildTapPayloadJson ignores extras without a message id`() {
        assertNull(NoctuaPushBridge.buildTapPayloadJson(Bundle().apply { putString("deeplink", "x") }))
        assertNull(NoctuaPushBridge.buildTapPayloadJson(null))
    }

    @Test
    fun `consumeTapIntent reports a tap only once`() {
        val intent = tapIntent("0:a")

        assertNotNull(NoctuaPushBridge.consumeTapIntent(intent))
        assertNull(NoctuaPushBridge.consumeTapIntent(intent))
    }

    @Test
    fun `cold start tap is dispatched on register`() {
        val activity = Robolectric.buildActivity(Activity::class.java, tapIntent("0:cold")).setup().get()

        NoctuaPushTapTracker.register(activity)

        assertEquals(1, taps.size)
        assertEquals("0:cold", JSONObject(taps.single()).getString("google.message_id"))
    }

    @Test
    fun `warm tap delivered as new intent is dispatched on resume, once`() {
        val controller = Robolectric.buildActivity(Activity::class.java, Intent(Intent.ACTION_MAIN)).setup()
        NoctuaPushTapTracker.register(controller.get())
        assertTrue(taps.isEmpty())

        // Same order Android uses for a tap on a running singleTask activity.
        controller.pause()
        controller.get().intent = tapIntent("0:warm")
        controller.resume()
        controller.pause().resume()

        assertEquals(1, taps.size)
        assertEquals("0:warm", JSONObject(taps.single()).getString("google.message_id"))
    }

    @Test
    fun `tap before the listener is registered is buffered`() {
        NoctuaPushBridge.setTappedListener(null)
        NoctuaPushBridge.dispatchTapped("{\"google.message_id\":\"0:early\"}")

        NoctuaPushBridge.setTappedListener { taps.add(it) }

        assertEquals(listOf("{\"google.message_id\":\"0:early\"}"), taps)
    }
}
