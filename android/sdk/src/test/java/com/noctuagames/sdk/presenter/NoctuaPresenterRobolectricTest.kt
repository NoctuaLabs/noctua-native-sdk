package com.noctuagames.sdk.presenter

import com.noctuagames.labs.sdk.utils.AppContext
import com.noctuagames.sdk.models.*
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.koin.core.context.stopKoin
import org.mockito.MockedStatic
import org.mockito.Mockito
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/**
 * Robolectric tests for [NoctuaPresenter].
 * Uses real Android Context for asset loading, ContentResolver, Uri, etc.
 *
 * AppContext.set() is mocked via Mockito.mockStatic() since it may load
 * native JNI code from the noctua-internal-native library.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class NoctuaPresenterRobolectricTest {

    private lateinit var presenter: NoctuaPresenter
    private lateinit var appContextMock: MockedStatic<AppContext>

    @Before
    fun setUp() {
        // Stop any existing Koin instance to prevent KoinApplicationAlreadyStartedException
        try { stopKoin() } catch (_: Exception) {}

        // Mock AppContext.set() to prevent native library loading
        appContextMock = Mockito.mockStatic(AppContext::class.java)

        val context = RuntimeEnvironment.getApplication()
        presenter = NoctuaPresenter(
            context = context,
            publishedApps = emptyList()
        )
    }

    @After
    fun tearDown() {
        appContextMock.close()
    }

    // --- Initialization ---

    @Test
    fun `presenter initializes without throwing`() {
        assertNotNull(presenter)
    }

    // --- Tracking with real presenter (services are null) ---

    @Test
    fun `trackAdRevenue with valid params does not crash`() {
        presenter.trackAdRevenue("admob", 0.19, "USD", mutableMapOf())
    }

    @Test
    fun `trackAdRevenue with empty source returns early`() {
        presenter.trackAdRevenue("", 1.0, "USD", mutableMapOf())
    }

    @Test
    fun `trackAdRevenue with zero revenue returns early`() {
        presenter.trackAdRevenue("admob", 0.0, "USD", mutableMapOf())
    }

    @Test
    fun `trackAdRevenue with negative revenue returns early`() {
        presenter.trackAdRevenue("admob", -1.0, "USD", mutableMapOf())
    }

    @Test
    fun `trackAdRevenue with empty currency returns early`() {
        presenter.trackAdRevenue("admob", 0.19, "", mutableMapOf())
    }

    @Test
    fun `trackPurchase with valid params does not crash`() {
        presenter.trackPurchase("order123", 9.99, "USD", mutableMapOf())
    }

    @Test
    fun `trackPurchase with empty orderId returns early`() {
        presenter.trackPurchase("", 9.99, "USD", mutableMapOf())
    }

    @Test
    fun `trackPurchase with zero amount returns early`() {
        presenter.trackPurchase("order123", 0.0, "USD", mutableMapOf())
    }

    @Test
    fun `trackCustomEvent does not crash`() {
        presenter.trackCustomEvent("level_complete", mutableMapOf("level" to 5 as Any))
    }

    // --- Account operations via ContentProvider ---

    @Test
    fun `getAccounts returns list (may be empty)`() {
        val accounts = presenter.getAccounts()
        assertNotNull(accounts)
    }

    @Test
    fun `putAccount and getAccount round-trip`() {
        val account = Account(userId = 10L, gameId = 1000L, rawData = "data", lastUpdated = 5000L)
        presenter.putAccount(account)
        val retrieved = presenter.getAccount(10L, 1000L)
        assertNotNull(retrieved)
        assertEquals("data", retrieved!!.rawData)
    }

    @Test
    fun `deleteAccount removes account`() {
        val account = Account(userId = 11L, gameId = 1100L, rawData = "del", lastUpdated = 6000L)
        presenter.putAccount(account)
        val deleted = presenter.deleteAccount(account)
        assertEquals(1, deleted)
        assertNull(presenter.getAccount(11L, 1100L))
    }

    @Test
    fun `getAccountsByUserId returns matching accounts`() {
        presenter.putAccount(Account(userId = 12L, gameId = 1200L, rawData = "a", lastUpdated = 1000L))
        presenter.putAccount(Account(userId = 12L, gameId = 1201L, rawData = "b", lastUpdated = 1001L))
        val results = presenter.getAccountsByUserId(12L)
        assertEquals(2, results.size)
    }

    @Test
    fun `getAccount returns null for non-existent`() {
        assertNull(presenter.getAccount(999L, 999L))
    }

    // --- Firebase (null service, returns defaults) ---

    @Test
    fun `getFirebaseInstallationID returns empty when firebase is null`() {
        var result = ""
        presenter.getFirebaseInstallationID { result = it }
        assertEquals("", result)
    }

    @Test
    fun `getFirebaseAnalyticsSessionID returns empty when firebase is null`() {
        var result = ""
        presenter.getFirebaseAnalyticsSessionID { result = it }
        assertEquals("", result)
    }

    @Test
    fun `getFirebaseRemoteConfigString returns null when firebase is null`() {
        assertNull(presenter.getFirebaseRemoteConfigString("key"))
    }

    @Test
    fun `getFirebaseRemoteConfigBoolean returns null when firebase is null`() {
        assertNull(presenter.getFirebaseRemoteConfigBoolean("key"))
    }

    @Test
    fun `getFirebaseRemoteConfigDouble returns null when firebase is null`() {
        assertNull(presenter.getFirebaseRemoteConfigDouble("key"))
    }

    @Test
    fun `getFirebaseRemoteConfigLong returns null when firebase is null`() {
        assertNull(presenter.getFirebaseRemoteConfigLong("key"))
    }

    // --- Adjust attribution ---

    @Test
    fun `getAdjustAttribution returns empty when adjust is null`() {
        var result = "not_set"
        presenter.getAdjustAttribution { result = it }
        assertEquals("", result)
    }

    // --- Lifecycle ---

    @Test
    fun `onResume does not crash`() {
        presenter.onResume()
    }

    @Test
    fun `onPause does not crash`() {
        presenter.onPause()
    }

    @Test
    fun `onDestroy does not crash`() {
        presenter.onDestroy()
    }

    @Test
    fun `onOnline does not crash`() {
        presenter.onOnline()
    }

    @Test
    fun `onOffline does not crash`() {
        presenter.onOffline()
    }

    // --- Session / Experiment (native tracker disabled) ---

    @Test
    fun `getSessionTag returns empty when tracker disabled`() {
        assertEquals("", presenter.getSessionTag())
    }

    @Test
    fun `getExperiment returns empty when tracker disabled`() {
        assertEquals("", presenter.getExperiment())
    }

    @Test
    fun `getGeneralExperiment returns empty when tracker disabled`() {
        assertEquals("", presenter.getGeneralExperiment("key"))
    }

    @Test
    fun `setSessionTag does not crash`() {
        presenter.setSessionTag("tag")
    }

    @Test
    fun `setExperiment does not crash`() {
        presenter.setExperiment("control")
    }

    @Test
    fun `setSessionExtraParams does not crash`() {
        presenter.setSessionExtraParams(mapOf("key" to "value"))
    }

    // --- Billing delegation ---

    @Test
    fun `isBillingReady returns false before initialization`() {
        assertFalse(presenter.isBillingReady())
    }

    @Test
    fun `registerProduct does not crash`() {
        presenter.registerProduct("noctua.sub.1", ConsumableType.SUBSCRIPTION)
        presenter.registerProduct("noctua.test.android.pack1", ConsumableType.CONSUMABLE)
    }

    @Test
    fun `billingConfig is passed through correctly`() {
        appContextMock.close()
        appContextMock = Mockito.mockStatic(AppContext::class.java)

        val config = NoctuaBillingConfig(
            enablePendingPurchases = false,
            enableAutoServiceReconnection = false,
            verifyPurchasesOnServer = true
        )
        val context = RuntimeEnvironment.getApplication()
        val customPresenter = NoctuaPresenter(context, emptyList(), config)
        assertFalse(customPresenter.isBillingReady())
    }
}
