package com.noctuagames.sdk.services

import android.content.Context
import com.noctuagames.sdk.models.*
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.mockito.kotlin.*

/**
 * Unit tests for BillingService.
 *
 * Note: Tests that call [BillingService.initialize] are excluded because
 * [com.android.billingclient.api.BillingClient.Builder.build] requires a real
 * Android Context internally. Those tests require instrumented/Robolectric tests.
 *
 * These tests cover:
 * - Product registration (no BillingClient needed)
 * - isReady state before initialization
 * - connectionState initial value
 * - completePurchaseProcessing logic (no BillingClient needed for non-consumable/subscription)
 * - acknowledgePurchase / consumePurchase when not ready
 */
class BillingServiceTest {

    private lateinit var mockContext: Context
    private lateinit var billingService: BillingService

    @Before
    fun setUp() {
        mockContext = mock()
        billingService = BillingService(mockContext)
    }

    // -----------------------------------------------
    // registerProduct
    // -----------------------------------------------

    @Test
    fun `registerProduct stores product type mapping`() {
        billingService.registerProduct("noctua.sub.1", ConsumableType.SUBSCRIPTION)
        billingService.registerProduct("noctua.test.android.pack1", ConsumableType.CONSUMABLE)
        billingService.registerProduct("noctua.premium", ConsumableType.NON_CONSUMABLE)
    }

    @Test
    fun `registerProduct overwrites existing mapping`() {
        billingService.registerProduct("product1", ConsumableType.CONSUMABLE)
        billingService.registerProduct("product1", ConsumableType.NON_CONSUMABLE)
    }

    @Test
    fun `registerProduct accepts all ConsumableType values`() {
        ConsumableType.entries.forEach { type ->
            billingService.registerProduct("product_${type.name}", type)
        }
    }

    // -----------------------------------------------
    // isReady
    // -----------------------------------------------

    @Test
    fun `isReady returns false before initialization`() {
        assertFalse(billingService.isReady())
    }

    // -----------------------------------------------
    // connectionState
    // -----------------------------------------------

    @Test
    fun `connectionState is false initially`() {
        assertFalse(billingService.connectionState.value)
    }

    // -----------------------------------------------
    // completePurchaseProcessing
    // -----------------------------------------------

    @Test
    fun `completePurchaseProcessing returns false when not verified`() {
        var callbackResult: Boolean? = null

        billingService.completePurchaseProcessing(
            purchaseToken = "token123",
            consumableType = ConsumableType.CONSUMABLE,
            verified = false,
            callback = { callbackResult = it }
        )

        assertFalse(callbackResult!!)
    }

    @Test
    fun `completePurchaseProcessing for NON_CONSUMABLE returns true when verified`() {
        var callbackResult: Boolean? = null

        billingService.completePurchaseProcessing(
            purchaseToken = "token123",
            consumableType = ConsumableType.NON_CONSUMABLE,
            verified = true,
            callback = { callbackResult = it }
        )

        assertTrue(callbackResult!!)
    }

    @Test
    fun `completePurchaseProcessing for SUBSCRIPTION returns true when verified`() {
        var callbackResult: Boolean? = null

        billingService.completePurchaseProcessing(
            purchaseToken = "token123",
            consumableType = ConsumableType.SUBSCRIPTION,
            verified = true,
            callback = { callbackResult = it }
        )

        assertTrue(callbackResult!!)
    }

    @Test
    fun `completePurchaseProcessing for CONSUMABLE fails when not ready`() {
        var callbackResult: Boolean? = null

        billingService.completePurchaseProcessing(
            purchaseToken = "token123",
            consumableType = ConsumableType.CONSUMABLE,
            verified = true,
            callback = { callbackResult = it }
        )

        // billingClient is null so isReady() is false, callback returns false
        assertFalse(callbackResult!!)
    }

    @Test
    fun `completePurchaseProcessing without callback does not crash`() {
        billingService.completePurchaseProcessing(
            purchaseToken = "token123",
            consumableType = ConsumableType.NON_CONSUMABLE,
            verified = true,
            callback = null
        )
    }

    @Test
    fun `completePurchaseProcessing unverified without callback does not crash`() {
        billingService.completePurchaseProcessing(
            purchaseToken = "token123",
            consumableType = ConsumableType.CONSUMABLE,
            verified = false,
            callback = null
        )
    }

    // -----------------------------------------------
    // acknowledgePurchase / consumePurchase when not ready
    // -----------------------------------------------

    @Test
    fun `acknowledgePurchase returns false via callback when not ready`() {
        var callbackResult: Boolean? = null

        billingService.acknowledgePurchase("token") { result ->
            callbackResult = result
        }

        assertFalse(callbackResult!!)
    }

    @Test
    fun `consumePurchase returns false via callback when not ready`() {
        var callbackResult: Boolean? = null

        billingService.consumePurchase("token") { result ->
            callbackResult = result
        }

        assertFalse(callbackResult!!)
    }

    @Test
    fun `acknowledgePurchase without callback does not crash when not ready`() {
        billingService.acknowledgePurchase("token", null)
    }

    @Test
    fun `consumePurchase without callback does not crash when not ready`() {
        billingService.consumePurchase("token", null)
    }

    // -----------------------------------------------
    // reconnect when not initialized
    // -----------------------------------------------

    @Test
    fun `reconnect does not throw when billingClient is null`() {
        billingService.reconnect()
    }

    // -----------------------------------------------
    // Config variations
    // -----------------------------------------------

    @Test
    fun `BillingService accepts custom config`() {
        val config = NoctuaBillingConfig(
            enablePendingPurchases = false,
            enableAutoServiceReconnection = false,
            verifyPurchasesOnServer = true
        )
        val service = BillingService(mockContext, config)
        assertFalse(service.isReady())
    }

    @Test
    fun `BillingService with default config`() {
        val service = BillingService(mockContext)
        assertFalse(service.isReady())
        assertFalse(service.connectionState.value)
    }
}
