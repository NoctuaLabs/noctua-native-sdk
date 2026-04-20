package com.noctuagames.sdk.inspector

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test

class LogTailerTest {

    private val phases = mutableListOf<Triple<String, String, Int>>()

    @Before
    fun setUp() {
        LogTailer._testReset()
        NoctuaInspectorBus.setEnabled(true)
        phases.clear()
        NoctuaInspectorBus.setCallback { provider, event, _, _, phase ->
            phases.add(Triple(provider, event, phase))
        }
    }

    @After
    fun tearDown() {
        LogTailer._testReset()
        NoctuaInspectorBus.setCallback(null)
        NoctuaInspectorBus.setEnabled(false)
    }

    // ---- Firebase ----

    @Test
    fun `firebase logging event upgrades pending to emitted`() {
        LogTailer.registerPending("Firebase", "purchase_completed")
        LogTailer.processLine(
            "11-11 11:11:11.111 1 1 V FA: Logging event (FE): purchase_completed, params: {}"
        )
        assertEquals(1, phases.size)
        assertEquals("Firebase", phases[0].first)
        assertEquals("purchase_completed", phases[0].second)
        assertEquals(NoctuaTrackerEventPhase.EMITTED.raw, phases[0].third)
        assertEquals(0, LogTailer._testPendingCount("Firebase", "purchase_completed"))
    }

    @Test
    fun `firebase logging event without pending is ignored`() {
        LogTailer.processLine(
            "11-11 11:11:11.111 1 1 V FA: Logging event (FE): stray, params: {}"
        )
        assertEquals(0, phases.size)
    }

    @Test
    fun `firebase uploading broadcasts uploading`() {
        LogTailer.registerPending("Firebase", "a")
        LogTailer.registerPending("Firebase", "b")
        LogTailer.processLine("11-11 11:11:11.111 1 1 V FA-SVC: Uploading data. events=2")
        val uploading = phases.filter { it.third == NoctuaTrackerEventPhase.UPLOADING.raw }
        assertEquals(2, uploading.size)
    }

    @Test
    fun `firebase successful upload clears pending`() {
        LogTailer.registerPending("Firebase", "a")
        LogTailer.registerPending("Firebase", "b")
        LogTailer.processLine("11-11 11:11:11.111 1 1 V FA-SVC: Successful upload. 2 events")
        assertEquals(0, LogTailer._testPendingCount("Firebase", "a"))
        assertEquals(0, LogTailer._testPendingCount("Firebase", "b"))
        val acks = phases.filter { it.third == NoctuaTrackerEventPhase.ACKNOWLEDGED.raw }
        assertEquals(2, acks.size)
    }

    @Test
    fun `firebase alternate format without FE suffix`() {
        LogTailer.registerPending("Firebase", "level_up")
        LogTailer.processLine("11-11 11:11:11.111 1 1 V FA: Logging event: level_up, params: {}")
        val emitted = phases.firstOrNull { it.third == NoctuaTrackerEventPhase.EMITTED.raw }
        assertEquals("level_up", emitted?.second)
    }

    // ---- Facebook ----

    @Test
    fun `facebook raw json line upgrades pending to emitted`() {
        LogTailer.registerPending("Facebook", "fb_mobile_purchase")
        LogTailer.processLine(
            "11-11 11:11:11.111 1 1 D FacebookSDK.AppEvents: Event raw JSON: {\"_eventName\":\"fb_mobile_purchase\"}"
        )
        val emitted = phases.firstOrNull { it.first == "Facebook" && it.third == NoctuaTrackerEventPhase.EMITTED.raw }
        assertEquals("fb_mobile_purchase", emitted?.second)
    }

    @Test
    fun `facebook flush success broadcasts acknowledged and clears`() {
        LogTailer.registerPending("Facebook", "a")
        LogTailer.registerPending("Facebook", "b")
        LogTailer.processLine(
            "11-11 11:11:11.111 1 1 D FacebookSDK.AppEventsManager: Flush result: SUCCESS"
        )
        val acks = phases.filter { it.first == "Facebook" && it.third == NoctuaTrackerEventPhase.ACKNOWLEDGED.raw }
        assertEquals(2, acks.size)
        assertEquals(0, LogTailer._testPendingCount("Facebook", "a"))
        assertEquals(0, LogTailer._testPendingCount("Facebook", "b"))
    }

    @Test
    fun `facebook flush server error broadcasts failed`() {
        LogTailer.registerPending("Facebook", "x")
        LogTailer.processLine(
            "11-11 11:11:11.111 1 1 W FacebookSDK.AppEventsManager: Flush result: SERVER_ERROR"
        )
        val failed = phases.firstOrNull { it.first == "Facebook" && it.third == NoctuaTrackerEventPhase.FAILED.raw }
        assertEquals("x", failed?.second)
        assertEquals(0, LogTailer._testPendingCount("Facebook", "x"))
    }

    // ---- Cross-provider isolation ----

    @Test
    fun `firebase success does not clear facebook pending`() {
        LogTailer.registerPending("Firebase", "fb_a")
        LogTailer.registerPending("Facebook", "fb_a")
        LogTailer.processLine("11-11 11:11:11.111 1 1 V FA-SVC: Successful upload. 1 events")
        assertEquals(0, LogTailer._testPendingCount("Firebase", "fb_a"))
        assertEquals(1, LogTailer._testPendingCount("Facebook", "fb_a"))
    }

    @Test
    fun `unrelated log line is ignored`() {
        LogTailer.registerPending("Firebase", "a")
        LogTailer.processLine("11-11 11:11:11.111 1 1 V SomethingElse: Logging event (FE): a, params: {}")
        assertNotEquals(0, LogTailer._testPendingCount("Firebase", "a"))
    }
}
