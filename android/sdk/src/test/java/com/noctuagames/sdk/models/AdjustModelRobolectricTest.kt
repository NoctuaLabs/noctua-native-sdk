package com.noctuagames.sdk.models

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.koin.core.context.stopKoin
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Robolectric tests for [toJsonString] extension function.
 * Requires real Android JSONObject implementation.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class AdjustModelRobolectricTest {

    @Before
    fun setUp() {
        try { stopKoin() } catch (_: Exception) {}
    }

    @Test
    fun `toJsonString with default values produces valid JSON`() {
        val attribution = NoctuaAdjustAttribution()
        val json = attribution.toJsonString()
        val obj = JSONObject(json)

        assertEquals("", obj.getString("trackerToken"))
        assertEquals("", obj.getString("trackerName"))
        assertEquals("", obj.getString("network"))
        assertEquals("", obj.getString("campaign"))
        assertEquals("", obj.getString("adGroup"))
        assertEquals("", obj.getString("creative"))
        assertEquals("", obj.getString("clickLabel"))
        assertEquals("", obj.getString("costType"))
        assertEquals(0.0, obj.getDouble("costAmount"), 0.001)
        assertEquals("", obj.getString("costConcurrency"))
        assertEquals("", obj.getString("fbInstallReferrer"))
    }

    @Test
    fun `toJsonString with populated values produces correct JSON`() {
        val attribution = NoctuaAdjustAttribution(
            trackerToken = "token_123",
            trackerName = "Test Tracker",
            network = "Facebook",
            campaign = "Summer Sale",
            adGroup = "Group A",
            creative = "Banner 1",
            clickLabel = "label_abc",
            costType = "CPI",
            costAmount = 1.5,
            costConcurrency = "USD",
            fbInstallReferrer = "fb_ref"
        )
        val json = attribution.toJsonString()
        val obj = JSONObject(json)

        assertEquals("token_123", obj.getString("trackerToken"))
        assertEquals("Test Tracker", obj.getString("trackerName"))
        assertEquals("Facebook", obj.getString("network"))
        assertEquals("Summer Sale", obj.getString("campaign"))
        assertEquals("Group A", obj.getString("adGroup"))
        assertEquals("Banner 1", obj.getString("creative"))
        assertEquals("label_abc", obj.getString("clickLabel"))
        assertEquals("CPI", obj.getString("costType"))
        assertEquals(1.5, obj.getDouble("costAmount"), 0.001)
        assertEquals("USD", obj.getString("costConcurrency"))
        assertEquals("fb_ref", obj.getString("fbInstallReferrer"))
    }

    @Test
    fun `toJsonString on null returns empty JSON object string`() {
        val nullAttribution: NoctuaAdjustAttribution? = null
        assertEquals("{}", nullAttribution.toJsonString())
    }

    @Test
    fun `toJsonString with null costAmount produces JSONObject NULL`() {
        val attribution = NoctuaAdjustAttribution(costAmount = null)
        val json = attribution.toJsonString()
        val obj = JSONObject(json)
        assertTrue(obj.isNull("costAmount"))
    }

    @Test
    fun `toJsonString with NaN costAmount produces JSONObject NULL`() {
        val attribution = NoctuaAdjustAttribution(costAmount = Double.NaN)
        val json = attribution.toJsonString()
        val obj = JSONObject(json)
        assertTrue(obj.isNull("costAmount"))
    }

    @Test
    fun `toJsonString with Infinity costAmount produces JSONObject NULL`() {
        val attribution = NoctuaAdjustAttribution(costAmount = Double.POSITIVE_INFINITY)
        val json = attribution.toJsonString()
        val obj = JSONObject(json)
        assertTrue(obj.isNull("costAmount"))
    }

    @Test
    fun `toJsonString with null fields puts null in JSON`() {
        val attribution = NoctuaAdjustAttribution(
            trackerToken = null,
            network = null
        )
        val json = attribution.toJsonString()
        val obj = JSONObject(json)
        assertTrue(obj.isNull("trackerToken"))
        assertTrue(obj.isNull("network"))
    }

    @Test
    fun `toJsonString produces parseable JSON with all 11 fields`() {
        val attribution = NoctuaAdjustAttribution(network = "Google Ads")
        val json = attribution.toJsonString()
        val obj = JSONObject(json)
        assertEquals(11, obj.length())
    }
}
