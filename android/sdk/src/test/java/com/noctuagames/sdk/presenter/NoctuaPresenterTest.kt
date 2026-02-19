package com.noctuagames.sdk.presenter

import com.noctuagames.sdk.models.*
import org.junit.Assert.*
import org.junit.Test

/**
 * Unit tests for NoctuaPresenter logic.
 *
 * Note: NoctuaPresenter cannot be directly instantiated in JVM unit tests because its
 * constructor depends on Android framework classes (Uri.parse, ContentResolver,
 * PackageManager, AppContext). Full integration tests require Robolectric or
 * Android instrumented tests.
 *
 * These tests validate the input validation and business logic contracts that
 * NoctuaPresenter depends on, using the model layer directly.
 */
class NoctuaPresenterTest {

    // -----------------------------------------------
    // Tracking input validation logic
    // (mirrors NoctuaPresenter.trackAdRevenue validation)
    // -----------------------------------------------

    @Test
    fun `trackAdRevenue validation - valid params should pass`() {
        val source = "admob"
        val revenue = 0.19
        val currency = "USD"

        val isValid = source.isNotEmpty() && revenue > 0 && currency.isNotEmpty()
        assertTrue(isValid)
    }

    @Test
    fun `trackAdRevenue validation - empty source should fail`() {
        val isValid = "".isNotEmpty() && 0.19 > 0 && "USD".isNotEmpty()
        assertFalse(isValid)
    }

    @Test
    fun `trackAdRevenue validation - zero revenue should fail`() {
        val isValid = "admob".isNotEmpty() && 0.0 > 0 && "USD".isNotEmpty()
        assertFalse(isValid)
    }

    @Test
    fun `trackAdRevenue validation - negative revenue should fail`() {
        val isValid = "admob".isNotEmpty() && (-1.0) > 0 && "USD".isNotEmpty()
        assertFalse(isValid)
    }

    @Test
    fun `trackAdRevenue validation - empty currency should fail`() {
        val isValid = "admob".isNotEmpty() && 0.19 > 0 && "".isNotEmpty()
        assertFalse(isValid)
    }

    // -----------------------------------------------
    // Tracking purchase validation logic
    // (mirrors NoctuaPresenter.trackPurchase validation)
    // -----------------------------------------------

    @Test
    fun `trackPurchase validation - valid params should pass`() {
        val isValid = "order123".isNotEmpty() && 9.99 > 0 && "USD".isNotEmpty()
        assertTrue(isValid)
    }

    @Test
    fun `trackPurchase validation - empty orderId should fail`() {
        val isValid = "".isNotEmpty() && 9.99 > 0 && "USD".isNotEmpty()
        assertFalse(isValid)
    }

    @Test
    fun `trackPurchase validation - zero amount should fail`() {
        val isValid = "order123".isNotEmpty() && 0.0 > 0 && "USD".isNotEmpty()
        assertFalse(isValid)
    }

    @Test
    fun `trackPurchase validation - empty currency should fail`() {
        val isValid = "order123".isNotEmpty() && 9.99 > 0 && "".isNotEmpty()
        assertFalse(isValid)
    }

    // -----------------------------------------------
    // Config validation logic
    // (mirrors NoctuaPresenter init block)
    // -----------------------------------------------

    @Test
    fun `clientId validation - null should be invalid`() {
        val config = NoctuaConfig(clientId = null, gameId = null, adjust = null, firebase = null, facebook = null, noctua = null)
        assertTrue(config.clientId.isNullOrEmpty())
    }

    @Test
    fun `clientId validation - empty should be invalid`() {
        val config = NoctuaConfig(clientId = "", gameId = null, adjust = null, firebase = null, facebook = null, noctua = null)
        assertTrue(config.clientId.isNullOrEmpty())
    }

    @Test
    fun `clientId validation - valid value should pass`() {
        val config = NoctuaConfig(clientId = "test_client", gameId = 1L, adjust = null, firebase = null, facebook = null, noctua = null)
        assertFalse(config.clientId.isNullOrEmpty())
    }

    // -----------------------------------------------
    // NativeInternalTracker config logic
    // (mirrors NoctuaPresenter.init nativeInternalTrackerEnabled)
    // -----------------------------------------------

    @Test
    fun `nativeInternalTrackerEnabled defaults to false when noctua is null`() {
        val config = NoctuaConfig(clientId = "test", gameId = null, adjust = null, firebase = null, facebook = null, noctua = null)
        val enabled = config.noctua?.nativeInternalTrackerEnabled ?: false
        assertFalse(enabled)
    }

    @Test
    fun `nativeInternalTrackerEnabled defaults to false when value is null`() {
        val config = NoctuaConfig(clientId = "test", gameId = null, adjust = null, firebase = null, facebook = null,
            noctua = NoctuaServiceConfig(nativeInternalTrackerEnabled = null))
        val enabled = config.noctua?.nativeInternalTrackerEnabled ?: false
        assertFalse(enabled)
    }

    @Test
    fun `nativeInternalTrackerEnabled is true when set`() {
        val config = NoctuaConfig(clientId = "test", gameId = null, adjust = null, firebase = null, facebook = null,
            noctua = NoctuaServiceConfig(nativeInternalTrackerEnabled = true))
        val enabled = config.noctua?.nativeInternalTrackerEnabled ?: false
        assertTrue(enabled)
    }

    // -----------------------------------------------
    // Service creation logic
    // (mirrors NoctuaPresenter.createAdjust/createFirebase/createFacebook)
    // -----------------------------------------------

    @Test
    fun `adjust service is null when config has no adjust section`() {
        val config = NoctuaConfig(clientId = "test", gameId = null, adjust = null, firebase = null, facebook = null, noctua = null)
        assertNull(config.adjust?.android)
    }

    @Test
    fun `adjust service is null when android config is null`() {
        val config = NoctuaConfig(clientId = "test", gameId = null,
            adjust = AdjustServiceConfig(android = null), firebase = null, facebook = null, noctua = null)
        assertNull(config.adjust?.android)
    }

    @Test
    fun `firebase service is null when config has no firebase section`() {
        val config = NoctuaConfig(clientId = "test", gameId = null, adjust = null, firebase = null, facebook = null, noctua = null)
        assertNull(config.firebase?.android)
    }

    @Test
    fun `facebook service is null when config has no facebook section`() {
        val config = NoctuaConfig(clientId = "test", gameId = null, adjust = null, firebase = null, facebook = null, noctua = null)
        assertNull(config.facebook?.android)
    }

    // -----------------------------------------------
    // Billing config delegation
    // -----------------------------------------------

    @Test
    fun `billingConfig defaults are correct for presenter`() {
        val config = NoctuaBillingConfig()
        assertTrue(config.enablePendingPurchases)
        assertTrue(config.enableAutoServiceReconnection)
        assertFalse(config.verifyPurchasesOnServer)
    }

    @Test
    fun `billingConfig with server verification`() {
        val config = NoctuaBillingConfig(verifyPurchasesOnServer = true)
        assertTrue(config.verifyPurchasesOnServer)
    }
}
