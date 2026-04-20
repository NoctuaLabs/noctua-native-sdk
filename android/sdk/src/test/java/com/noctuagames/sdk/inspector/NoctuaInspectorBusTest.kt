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
    }

    @After
    fun tearDown() {
        NoctuaInspectorBus.setCallback(null)
        NoctuaInspectorBus.setEnabled(false)
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
}
