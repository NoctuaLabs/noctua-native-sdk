package com.noctuagames.sdk.services

import org.json.JSONObject
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Robolectric tests for [NoctuaPushBridge] — needs the real org.json implementation.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], application = android.app.Application::class)
class NoctuaPushBridgeTest {

    @Before
    fun setUp() = NoctuaPushBridge.reset()

    @After
    fun tearDown() = NoctuaPushBridge.reset()

    @Test
    fun `buildPayloadJson puts notification, data and message id`() {
        val json = JSONObject(
            NoctuaPushBridge.buildPayloadJson(
                messageId = "0:123",
                title = "Hello",
                body = "World",
                data = mapOf("deeplink" to "game://shop"),
            )
        )

        assertEquals("Hello", json.getJSONObject("notification").getString("title"))
        assertEquals("World", json.getJSONObject("notification").getString("body"))
        assertEquals("game://shop", json.getString("deeplink"))
        assertEquals("0:123", json.getString("google.message_id"))
    }

    @Test
    fun `buildPayloadJson omits notification for data-only message`() {
        val json = JSONObject(
            NoctuaPushBridge.buildPayloadJson(null, null, null, mapOf("route" to "inbox"))
        )

        assertFalse(json.has("notification"))
        assertFalse(json.has("google.message_id"))
        assertEquals("inbox", json.getString("route"))
    }

    @Test
    fun `dispatchReceived delivers to registered listener`() {
        val received = mutableListOf<String>()
        NoctuaPushBridge.setReceivedListener { received.add(it) }

        NoctuaPushBridge.dispatchReceived("{\"a\":1}")

        assertEquals(listOf("{\"a\":1}"), received)
    }

    @Test
    fun `payload received before registration is buffered and delivered once`() {
        NoctuaPushBridge.dispatchReceived("{\"first\":1}")
        NoctuaPushBridge.dispatchReceived("{\"last\":1}")

        val received = mutableListOf<String>()
        NoctuaPushBridge.setReceivedListener { received.add(it) }
        NoctuaPushBridge.setReceivedListener { received.add(it) }

        assertEquals(listOf("{\"last\":1}"), received)
    }

    @Test
    fun `listener exception does not propagate`() {
        NoctuaPushBridge.setReceivedListener { throw IllegalStateException("boom") }

        NoctuaPushBridge.dispatchReceived("{}")
    }
}
