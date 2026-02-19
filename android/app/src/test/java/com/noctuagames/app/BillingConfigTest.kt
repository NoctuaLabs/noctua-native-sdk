package com.noctuagames.app

import com.noctuagames.sdk.models.NoctuaBillingConfig
import org.junit.Assert.*
import org.junit.Test

/**
 * Unit tests for BillingConfig usage in the sample app.
 * Validates that the billing configuration matches expected defaults
 * and behaves correctly with different settings.
 */
class BillingConfigTest {

    @Test
    fun `sample app billing config matches expected values`() {
        // As configured in MainActivity
        val config = NoctuaBillingConfig(
            enablePendingPurchases = true,
            enableAutoServiceReconnection = true,
            verifyPurchasesOnServer = false
        )

        assertTrue(config.enablePendingPurchases)
        assertTrue(config.enableAutoServiceReconnection)
        assertFalse(config.verifyPurchasesOnServer)
    }

    @Test
    fun `default billing config is equivalent to sample app config`() {
        val defaultConfig = NoctuaBillingConfig()
        val sampleAppConfig = NoctuaBillingConfig(
            enablePendingPurchases = true,
            enableAutoServiceReconnection = true,
            verifyPurchasesOnServer = false
        )

        assertEquals(defaultConfig, sampleAppConfig)
    }

    @Test
    fun `server verification config differs from default`() {
        val defaultConfig = NoctuaBillingConfig()
        val serverVerifyConfig = NoctuaBillingConfig(verifyPurchasesOnServer = true)

        assertNotEquals(defaultConfig, serverVerifyConfig)
        assertTrue(serverVerifyConfig.verifyPurchasesOnServer)
    }

    @Test
    fun `billing config data class copy works`() {
        val original = NoctuaBillingConfig()
        val modified = original.copy(verifyPurchasesOnServer = true)

        assertFalse(original.verifyPurchasesOnServer)
        assertTrue(modified.verifyPurchasesOnServer)
        assertEquals(original.enablePendingPurchases, modified.enablePendingPurchases)
        assertEquals(original.enableAutoServiceReconnection, modified.enableAutoServiceReconnection)
    }
}
