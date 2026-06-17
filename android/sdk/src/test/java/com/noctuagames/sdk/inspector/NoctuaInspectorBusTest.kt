package com.noctuagames.sdk.inspector

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class NoctuaInspectorBusTest {

    @Before
    fun setUp() {
        NoctuaInspectorBus.setCallback(null)
        NoctuaInspectorBus.setEnabled(false)
        NoctuaInspectorBus.setLogCallback(null)
        NoctuaInspectorBus.setLogStreamEnabled(false)
    }

    @After
    fun tearDown() {
        NoctuaInspectorBus.setCallback(null)
        NoctuaInspectorBus.setEnabled(false)
        NoctuaInspectorBus.setLogCallback(null)
        NoctuaInspectorBus.setLogStreamEnabled(false)
    }

    @Test
    fun `emit noop when disabled`() {
        var fired = false
        NoctuaInspectorBus.setCallback { _, _, _, _, _ -> fired = true }
        NoctuaInspectorBus.emit("Firebase", "test", phase = NoctuaTrackerEventPhase.QUEUED)
        assertFalse("callback must not fire when bus disabled", fired)
    }

    @Test
    fun `emit noop without callback`() {
        NoctuaInspectorBus.setEnabled(true)
        // Must not throw when callback is null
        NoctuaInspectorBus.emit("Firebase", "test", phase = NoctuaTrackerEventPhase.QUEUED)
    }

    @Test
    fun `emit delivers provider event and phase`() {
        NoctuaInspectorBus.setEnabled(true)
        var captured: Triple<String, String, Int>? = null
        NoctuaInspectorBus.setCallback { provider, event, _, _, phase ->
            captured = Triple(provider, event, phase)
        }

        NoctuaInspectorBus.emit("Adjust", "purchase", phase = NoctuaTrackerEventPhase.ACKNOWLEDGED)

        assertEquals("Adjust", captured?.first)
        assertEquals("purchase", captured?.second)
        assertEquals(NoctuaTrackerEventPhase.ACKNOWLEDGED.raw, captured?.third)
    }

    @Test
    fun `emit serializes payload to json`() {
        NoctuaInspectorBus.setEnabled(true)
        var payloadJson: String? = null
        NoctuaInspectorBus.setCallback { _, _, payload, _, _ -> payloadJson = payload }

        NoctuaInspectorBus.emit(
            "Firebase",
            "purchase_completed",
            mapOf("currency" to "USD", "value" to 4.99),
            phase = NoctuaTrackerEventPhase.QUEUED
        )

        // Assert against the raw JSON string — avoids Android's stubbed
        // `JSONObject` returning default values in local unit tests.
        val json = payloadJson ?: ""
        assertTrue("payload must include currency: $json", json.contains("\"currency\":\"USD\""))
        assertTrue("payload must include value: $json",    json.contains("\"value\":4.99"))
        assertTrue("payload is an object: $json",          json.startsWith("{") && json.endsWith("}"))
    }

    @Test
    fun `emit handles empty dicts`() {
        NoctuaInspectorBus.setEnabled(true)
        var payload: String? = null
        var extra: String? = null
        NoctuaInspectorBus.setCallback { _, _, p, e, _ -> payload = p; extra = e }

        NoctuaInspectorBus.emit("Mock", "e", phase = NoctuaTrackerEventPhase.QUEUED)

        assertEquals("{}", payload)
        assertEquals("{}", extra)
    }

    @Test
    fun `phase raw values stable across JNI`() {
        // These cross the Unity AndroidJavaProxy boundary; changing would break
        // the iOS/Android/Unity tri-contract.
        assertEquals(0, NoctuaTrackerEventPhase.QUEUED.raw)
        assertEquals(1, NoctuaTrackerEventPhase.SENDING.raw)
        assertEquals(2, NoctuaTrackerEventPhase.EMITTED.raw)
        assertEquals(3, NoctuaTrackerEventPhase.UPLOADING.raw)
        assertEquals(4, NoctuaTrackerEventPhase.ACKNOWLEDGED.raw)
        assertEquals(5, NoctuaTrackerEventPhase.FAILED.raw)
        assertEquals(6, NoctuaTrackerEventPhase.TIMED_OUT.raw)
    }

    @Test
    fun `fromRaw maps known values`() {
        assertEquals(NoctuaTrackerEventPhase.ACKNOWLEDGED, NoctuaTrackerEventPhase.fromRaw(4))
    }

    @Test
    fun `fromRaw unknown defaults to queued`() {
        assertEquals(NoctuaTrackerEventPhase.QUEUED, NoctuaTrackerEventPhase.fromRaw(999))
    }

    @Test
    fun `isEnabled reflects setEnabled`() {
        NoctuaInspectorBus.setEnabled(true)
        assertTrue(NoctuaInspectorBus.isEnabled())
        NoctuaInspectorBus.setEnabled(false)
        assertFalse(NoctuaInspectorBus.isEnabled())
    }

    @Test
    fun `serialize handles all value shapes`() {
        val json = NoctuaInspectorBus.serialize(
            mapOf(
                "s" to "v", "n" to 4.99, "i" to 7, "b" to true, "nullKey" to null,
                "list" to listOf(1, 2), "nested" to mapOf("k" to "x")
            )
        )
        assertTrue(json.contains("\"s\":\"v\""))
        assertTrue(json.contains("\"b\":true"))
        assertTrue(json.contains("\"nullKey\":null"))
        assertTrue(json.contains("\"list\":[1,2]"))
        assertTrue(json.contains("\"nested\":{\"k\":\"x\"}"))
    }

    @Test
    fun `serialize escapes control characters`() {
        val out = NoctuaInspectorBus.serialize(mapOf("q" to "a\"b\\c\nd\te"))
        assertTrue(out.contains("\\\""))
        assertTrue(out.contains("\\\\"))
        assertTrue(out.contains("\\n"))
        assertTrue(out.contains("\\t"))
    }

    @Test
    fun `serialize coerces NaN and infinity to null`() {
        val out = NoctuaInspectorBus.serialize(mapOf("nan" to Double.NaN, "inf" to Double.POSITIVE_INFINITY))
        assertTrue(out.contains("\"nan\":null"))
        assertTrue(out.contains("\"inf\":null"))
    }

    @Test
    fun `serialize empty map is empty object`() {
        assertEquals("{}", NoctuaInspectorBus.serialize(emptyMap()))
    }

    // ----- log-stream channel -----

    @Test
    fun `log stream disabled by default`() {
        assertFalse(NoctuaInspectorBus.isLogStreamEnabled())
    }

    @Test
    fun `setLogStreamEnabled toggles flag`() {
        NoctuaInspectorBus.setLogStreamEnabled(true)
        assertTrue(NoctuaInspectorBus.isLogStreamEnabled())
        NoctuaInspectorBus.setLogStreamEnabled(false)
        assertFalse(NoctuaInspectorBus.isLogStreamEnabled())
    }

    @Test
    fun `emitLog noop when bus disabled`() {
        var fired = false
        NoctuaInspectorBus.setLogStreamEnabled(true)
        NoctuaInspectorBus.setLogCallback { _, _, _, _, _ -> fired = true }
        NoctuaInspectorBus.emitLog(3, "Android", "t", "m", 1L)
        assertFalse(fired)
    }

    @Test
    fun `emitLog noop when log stream disabled`() {
        var fired = false
        NoctuaInspectorBus.setEnabled(true)
        NoctuaInspectorBus.setLogCallback { _, _, _, _, _ -> fired = true }
        NoctuaInspectorBus.emitLog(3, "Android", "t", "m", 1L)
        assertFalse(fired)
    }

    @Test
    fun `emitLog delivers when both enabled`() {
        NoctuaInspectorBus.setEnabled(true)
        NoctuaInspectorBus.setLogStreamEnabled(true)
        var captured: Array<Any?>? = null
        NoctuaInspectorBus.setLogCallback { l, s, t, m, ts -> captured = arrayOf(l, s, t, m, ts) }

        NoctuaInspectorBus.emitLog(4, "Noctua", "Tag", "hello", 42L)

        assertEquals(4, captured!![0])
        assertEquals("Noctua", captured!![1])
        assertEquals("hello", captured!![3])
        assertEquals(42L, captured!![4])
    }
}
