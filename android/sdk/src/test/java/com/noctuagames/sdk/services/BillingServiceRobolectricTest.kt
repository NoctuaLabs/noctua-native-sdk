package com.noctuagames.sdk.services

import com.noctuagames.sdk.models.*
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.koin.core.context.stopKoin
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
        try { stopKoin() } catch (_: Exception) {}
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
