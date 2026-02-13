package com.noctuagames.sdk.models

import org.junit.Assert.*
import org.junit.Test

class ConfigModelTest {

    @Test
    fun `NoctuaConfig stores all fields`() {
        val config = NoctuaConfig(
            clientId = "test_client",
            gameId = 42L,
            adjust = null,
            firebase = null,
            facebook = null,
            noctua = null
        )
        assertEquals("test_client", config.clientId)
        assertEquals(42L, config.gameId)
        assertNull(config.adjust)
        assertNull(config.firebase)
        assertNull(config.facebook)
        assertNull(config.noctua)
    }

    @Test
    fun `NoctuaServiceConfig stores nativeInternalTrackerEnabled`() {
        val serviceConfig = NoctuaServiceConfig(nativeInternalTrackerEnabled = true)
        assertTrue(serviceConfig.nativeInternalTrackerEnabled!!)

        val disabledConfig = NoctuaServiceConfig(nativeInternalTrackerEnabled = false)
        assertFalse(disabledConfig.nativeInternalTrackerEnabled!!)

        val nullConfig = NoctuaServiceConfig(nativeInternalTrackerEnabled = null)
        assertNull(nullConfig.nativeInternalTrackerEnabled)
    }

    @Test
    fun `AdjustServiceAndroidConfig stores all fields`() {
        val adjustConfig = AdjustServiceAndroidConfig(
            appToken = "token123",
            environment = "sandbox",
            customEventDisabled = true,
            eventMap = mapOf("purchase" to "event_abc")
        )
        assertEquals("token123", adjustConfig.appToken)
        assertEquals("sandbox", adjustConfig.environment)
        assertTrue(adjustConfig.customEventDisabled)
        assertEquals("event_abc", adjustConfig.eventMap!!["purchase"])
    }

    @Test
    fun `AdjustServiceAndroidConfig customEventDisabled defaults to false`() {
        val config = AdjustServiceAndroidConfig(
            appToken = "token",
            environment = null,
            eventMap = null
        )
        assertFalse(config.customEventDisabled)
    }

    @Test
    fun `FirebaseServiceAndroidConfig defaults`() {
        val config = FirebaseServiceAndroidConfig()
        assertFalse(config.customEventDisabled)
    }

    @Test
    fun `FacebookServiceAndroidConfig defaults`() {
        val config = FacebookServiceAndroidConfig()
        assertFalse(config.enableDebug)
        assertTrue(config.advertiserIdCollectionEnabled)
        assertTrue(config.autoLogAppEventsEnabled)
        assertFalse(config.customEventDisabled)
    }

    @Test
    fun `FacebookServiceAndroidConfig custom values`() {
        val config = FacebookServiceAndroidConfig(
            enableDebug = true,
            advertiserIdCollectionEnabled = false,
            autoLogAppEventsEnabled = false,
            customEventDisabled = true
        )
        assertTrue(config.enableDebug)
        assertFalse(config.advertiserIdCollectionEnabled)
        assertFalse(config.autoLogAppEventsEnabled)
        assertTrue(config.customEventDisabled)
    }

    @Test
    fun `NoctuaConfig with full service configs`() {
        val config = NoctuaConfig(
            clientId = "client_full",
            gameId = 1L,
            adjust = AdjustServiceConfig(
                android = AdjustServiceAndroidConfig(
                    appToken = "adj_token",
                    environment = "production",
                    eventMap = mapOf("login" to "ev1")
                )
            ),
            firebase = FirebaseServiceConfig(
                android = FirebaseServiceAndroidConfig(customEventDisabled = true)
            ),
            facebook = FacebookServiceConfig(
                android = FacebookServiceAndroidConfig(enableDebug = true)
            ),
            noctua = NoctuaServiceConfig(nativeInternalTrackerEnabled = true)
        )
        assertNotNull(config.adjust?.android)
        assertNotNull(config.firebase?.android)
        assertNotNull(config.facebook?.android)
        assertTrue(config.noctua?.nativeInternalTrackerEnabled!!)
        assertEquals("adj_token", config.adjust?.android?.appToken)
    }
}
