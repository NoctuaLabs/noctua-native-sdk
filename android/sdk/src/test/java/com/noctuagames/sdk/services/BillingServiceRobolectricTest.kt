package com.noctuagames.sdk.services

import com.noctuagames.sdk.models.*
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/**
 * Robolectric tests for [BillingService].
 * Uses real Android Context so BillingClient.Builder.build() can succeed.
 *
 * Note: BillingClient will build but startConnection() will not actually
 * connect to Google Play in test environment. This is expected.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class BillingServiceRobolectricTest {

    private lateinit var billingService: BillingService

    @Before
    fun setUp() {
        try {
            val clazz = Class.forName("org.koin.core.context.GlobalContext")
            val instance = clazz.getDeclaredField("INSTANCE").get(null)
            clazz.getMethod("stopKoin").invoke(instance)
        } catch (_: Exception) {}
        val context = RuntimeEnvironment.getApplication()
        billingService = BillingService(context)
    }

    @Test
    fun `initialize does not throw with real context`() {
        billingService.initialize()
    }

    @Test
    fun `initialize with listener wires up listener`() {
        var errorReceived = false
        billingService.initialize(object : BillingEventListener {
            override fun onPurchaseCompleted(result: NoctuaPurchaseResult) {}
            override fun onPurchaseUpdated(result: NoctuaPurchaseResult) {}
            override fun onProductDetailsLoaded(products: List<NoctuaProductDetails>) {}
            override fun onQueryPurchasesCompleted(purchases: List<NoctuaPurchaseResult>) {}
            override fun onRestorePurchasesCompleted(purchases: List<NoctuaPurchaseResult>) {}
            override fun onProductPurchaseStatusResult(status: NoctuaProductPurchaseStatus) {}
            override fun onServerVerificationRequired(result: NoctuaPurchaseResult, consumableType: ConsumableType) {}
            override fun onBillingError(error: BillingErrorCode, message: String) {
                errorReceived = true
            }
        })
        // BillingClient builds successfully but connection won't establish in test
    }

    @Test
    fun `double initialize is idempotent`() {
        billingService.initialize()
        billingService.initialize() // Should log warning, not crash
    }

    /**
     * Recovery tests for the case that used to leave billing permanently dead: the first
     * connection attempt fails (Google Play unavailable at launch), and every later retry was a
     * no-op because initialize() returned early on isInitialized and reconnect() called
     * startConnection() again on the same, unrevivable BillingClient.
     *
     * A BillingClient allows a single connection lifecycle, so recovery is only possible by
     * building a new one. billingClientBuildCount is what makes that observable here: Robolectric
     * can build a real client but never reaches Google Play, which is exactly the never-connected
     * state these tests need.
     *
     * connectAttemptTimeoutMs is zeroed so the in-flight guard does not suppress the immediate
     * back-to-back retries; that guard has its own test below.
     */
    @Test
    fun `reconnect builds a fresh billing client when never connected`() {
        billingService.connectAttemptTimeoutMs = 0
        billingService.initialize()
        assertEquals(1, billingService.billingClientBuildCount)

        billingService.reconnect()

        assertEquals(
            "reconnect must rebuild the client; retrying the dead one can never recover",
            2,
            billingService.billingClientBuildCount
        )
    }

    @Test
    fun `initialize after a failed connection retries instead of returning early`() {
        billingService.connectAttemptTimeoutMs = 0
        billingService.initialize()
        assertEquals(1, billingService.billingClientBuildCount)

        // What the SDK's readiness loop does: call initialize() again while billing is not ready.
        billingService.initialize()

        assertEquals(
            "a second initialize while disconnected must attempt recovery, not no-op",
            2,
            billingService.billingClientBuildCount
        )
    }

    @Test
    fun `repeated reconnects keep rebuilding while disconnected`() {
        billingService.connectAttemptTimeoutMs = 0
        billingService.initialize()

        repeat(3) { billingService.reconnect() }

        assertEquals(4, billingService.billingClientBuildCount)
    }

    @Test
    fun `reconnect is suppressed while a connection attempt is still in flight`() {
        billingService.initialize()
        assertEquals(1, billingService.billingClientBuildCount)

        // Robolectric finishes the handshake synchronously, so stage an attempt that is still
        // outstanding — the real-device case this guard exists for. Replacing a live handshake
        // would mean no attempt ever gets far enough to succeed.
        billingService.connectAttemptStartedAtNanos = System.nanoTime()

        billingService.reconnect()

        assertEquals(
            "an in-flight handshake must not be replaced, or no attempt ever completes",
            1,
            billingService.billingClientBuildCount
        )
    }

    @Test
    fun `in-flight guard expires so a stuck attempt cannot block recovery forever`() {
        billingService.initialize()
        assertEquals(1, billingService.billingClientBuildCount)

        // Play accepted the connection request and then never called back: without an expiry this
        // would wedge reconnection for the rest of the session.
        billingService.connectAttemptStartedAtNanos = System.nanoTime()
        billingService.reconnect()
        assertEquals("still within the deadline", 1, billingService.billingClientBuildCount)

        billingService.connectAttemptTimeoutMs = 0

        billingService.reconnect()

        assertEquals(
            "once the deadline passes, recovery must be possible again",
            2,
            billingService.billingClientBuildCount
        )
    }

    @Test
    fun `reconnect without initialize does not crash`() {
        billingService.connectAttemptTimeoutMs = 0
        billingService.reconnect()
    }

    @Test
    fun `initialize after dispose starts a new client`() {
        billingService.initialize()
        billingService.dispose()

        val revived = BillingService(RuntimeEnvironment.getApplication())
        revived.initialize()

        assertEquals(1, revived.billingClientBuildCount)
    }

    @Test
    fun `dispose after initialize does not crash`() {
        billingService.initialize()
        billingService.dispose()
    }

    @Test
    fun `dispose without initialize does not crash`() {
        billingService.dispose()
    }

    @Test
    fun `registerProduct works after initialize`() {
        billingService.initialize()
        billingService.registerProduct("test.product", ConsumableType.CONSUMABLE)
        billingService.registerProduct("test.sub", ConsumableType.SUBSCRIPTION)
    }

    @Test
    fun `initialize with custom config does not throw`() {
        val context = RuntimeEnvironment.getApplication()
        val service = BillingService(context, NoctuaBillingConfig(
            enableAutoServiceReconnection = false,
            verifyPurchasesOnServer = true
        ))
        service.initialize()
    }
}
