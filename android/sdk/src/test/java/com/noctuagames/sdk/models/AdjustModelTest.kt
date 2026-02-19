package com.noctuagames.sdk.models

import org.junit.Assert.*
import org.junit.Test

/**
 * Unit tests for Adjust models.
 *
 * Note: Tests for [toJsonString] are excluded because [org.json.JSONObject]
 * is an Android framework class that returns null stubs in JVM unit tests.
 * Those tests require Robolectric or Android instrumented tests.
 */
class AdjustModelTest {

    @Test
    fun `NoctuaAdjustAttribution has correct defaults`() {
        val attribution = NoctuaAdjustAttribution()
        assertEquals("", attribution.trackerToken)
        assertEquals("", attribution.trackerName)
        assertEquals("", attribution.network)
        assertEquals("", attribution.campaign)
        assertEquals("", attribution.adGroup)
        assertEquals("", attribution.creative)
        assertEquals("", attribution.clickLabel)
        assertEquals("", attribution.costType)
        assertEquals(0.0, attribution.costAmount!!, 0.001)
        assertEquals("", attribution.costConcurrency)
        assertEquals("", attribution.fbInstallReferrer)
    }

    @Test
    fun `NoctuaAdjustAttribution stores all fields`() {
        val attribution = NoctuaAdjustAttribution(
            trackerToken = "tracker_token_123",
            trackerName = "My Tracker",
            network = "Facebook",
            campaign = "Summer Sale",
            adGroup = "Group A",
            creative = "Banner 1",
            clickLabel = "label_abc",
            costType = "CPI",
            costAmount = 1.5,
            costConcurrency = "USD",
            fbInstallReferrer = "fb_referrer"
        )
        assertEquals("tracker_token_123", attribution.trackerToken)
        assertEquals("My Tracker", attribution.trackerName)
        assertEquals("Facebook", attribution.network)
        assertEquals("Summer Sale", attribution.campaign)
        assertEquals("Group A", attribution.adGroup)
        assertEquals("Banner 1", attribution.creative)
        assertEquals("label_abc", attribution.clickLabel)
        assertEquals("CPI", attribution.costType)
        assertEquals(1.5, attribution.costAmount!!, 0.001)
        assertEquals("USD", attribution.costConcurrency)
        assertEquals("fb_referrer", attribution.fbInstallReferrer)
    }

    @Test
    fun `NoctuaAdjustAttribution data class equality`() {
        val a1 = NoctuaAdjustAttribution(trackerToken = "t1", network = "fb")
        val a2 = NoctuaAdjustAttribution(trackerToken = "t1", network = "fb")
        val a3 = NoctuaAdjustAttribution(trackerToken = "t2", network = "google")

        assertEquals(a1, a2)
        assertNotEquals(a1, a3)
    }

    @Test
    fun `NoctuaAdjustAttribution copy works`() {
        val original = NoctuaAdjustAttribution(network = "Facebook", campaign = "Summer")
        val copied = original.copy(campaign = "Winter")

        assertEquals("Facebook", copied.network)
        assertEquals("Winter", copied.campaign)
    }

    @Test
    fun `NoctuaAdjustAttribution allows null costAmount`() {
        val attribution = NoctuaAdjustAttribution(costAmount = null)
        assertNull(attribution.costAmount)
    }

    @Test
    fun `toJsonString on null returns empty JSON object`() {
        val nullAttribution: NoctuaAdjustAttribution? = null
        val result = nullAttribution.toJsonString()
        assertEquals("{}", result)
    }

    @Test
    fun `AdjustServiceConfig stores android config`() {
        val config = AdjustServiceConfig(
            android = AdjustServiceAndroidConfig(
                appToken = "test_token",
                environment = "sandbox",
                eventMap = mapOf("purchase" to "event1")
            )
        )
        assertNotNull(config.android)
        assertEquals("test_token", config.android!!.appToken)
    }

    @Test
    fun `AdjustServiceConfig with null android`() {
        val config = AdjustServiceConfig(android = null)
        assertNull(config.android)
    }
}
