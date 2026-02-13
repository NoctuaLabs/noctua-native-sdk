package com.noctuagames.sdk.models

import org.junit.Assert.*
import org.junit.Test

class BillingModelTest {

    // -----------------------------------------------
    // BillingErrorCode
    // -----------------------------------------------

    @Test
    fun `fromCode returns correct BillingErrorCode for known codes`() {
        assertEquals(BillingErrorCode.OK, BillingErrorCode.fromCode(0))
        assertEquals(BillingErrorCode.USER_CANCELED, BillingErrorCode.fromCode(1))
        assertEquals(BillingErrorCode.SERVICE_UNAVAILABLE, BillingErrorCode.fromCode(2))
        assertEquals(BillingErrorCode.BILLING_UNAVAILABLE, BillingErrorCode.fromCode(3))
        assertEquals(BillingErrorCode.ITEM_UNAVAILABLE, BillingErrorCode.fromCode(4))
        assertEquals(BillingErrorCode.DEVELOPER_ERROR, BillingErrorCode.fromCode(5))
        assertEquals(BillingErrorCode.ERROR, BillingErrorCode.fromCode(6))
        assertEquals(BillingErrorCode.ITEM_ALREADY_OWNED, BillingErrorCode.fromCode(7))
        assertEquals(BillingErrorCode.ITEM_NOT_OWNED, BillingErrorCode.fromCode(8))
        assertEquals(BillingErrorCode.NETWORK_ERROR, BillingErrorCode.fromCode(12))
        assertEquals(BillingErrorCode.SERVICE_DISCONNECTED, BillingErrorCode.fromCode(-1))
        assertEquals(BillingErrorCode.FEATURE_NOT_SUPPORTED, BillingErrorCode.fromCode(-2))
    }

    @Test
    fun `fromCode returns ERROR for unknown code`() {
        assertEquals(BillingErrorCode.ERROR, BillingErrorCode.fromCode(999))
        assertEquals(BillingErrorCode.ERROR, BillingErrorCode.fromCode(-100))
    }

    // -----------------------------------------------
    // PurchaseState
    // -----------------------------------------------

    @Test
    fun `fromState returns correct PurchaseState for known states`() {
        assertEquals(PurchaseState.UNSPECIFIED, PurchaseState.fromState(0))
        assertEquals(PurchaseState.PURCHASED, PurchaseState.fromState(1))
        assertEquals(PurchaseState.PENDING, PurchaseState.fromState(2))
    }

    @Test
    fun `fromState returns UNSPECIFIED for unknown state`() {
        assertEquals(PurchaseState.UNSPECIFIED, PurchaseState.fromState(99))
        assertEquals(PurchaseState.UNSPECIFIED, PurchaseState.fromState(-1))
    }

    // -----------------------------------------------
    // NoctuaPurchaseResult
    // -----------------------------------------------

    @Test
    fun `isPurchased returns true when state is PURCHASED`() {
        val result = NoctuaPurchaseResult(
            success = true,
            purchaseState = PurchaseState.PURCHASED
        )
        assertTrue(result.isPurchased())
        assertFalse(result.isPending())
    }

    @Test
    fun `isPending returns true when state is PENDING`() {
        val result = NoctuaPurchaseResult(
            success = false,
            purchaseState = PurchaseState.PENDING
        )
        assertTrue(result.isPending())
        assertFalse(result.isPurchased())
    }

    @Test
    fun `isPurchased and isPending return false for UNSPECIFIED`() {
        val result = NoctuaPurchaseResult(
            success = false,
            purchaseState = PurchaseState.UNSPECIFIED
        )
        assertFalse(result.isPurchased())
        assertFalse(result.isPending())
    }

    @Test
    fun `NoctuaPurchaseResult has correct default values`() {
        val result = NoctuaPurchaseResult(success = false)
        assertEquals(BillingErrorCode.OK, result.errorCode)
        assertEquals(PurchaseState.UNSPECIFIED, result.purchaseState)
        assertEquals("", result.productId)
        assertNull(result.orderId)
        assertEquals("", result.purchaseToken)
        assertEquals(0L, result.purchaseTime)
        assertFalse(result.isAcknowledged)
        assertFalse(result.isAutoRenewing)
        assertEquals(1, result.quantity)
        assertEquals("", result.message)
        assertEquals("", result.originalJson)
    }

    @Test
    fun `NoctuaPurchaseResult stores all fields correctly`() {
        val result = NoctuaPurchaseResult(
            success = true,
            errorCode = BillingErrorCode.OK,
            purchaseState = PurchaseState.PURCHASED,
            productId = "noctua.sub.1",
            orderId = "GPA.1234",
            purchaseToken = "token123",
            purchaseTime = 1700000000L,
            isAcknowledged = true,
            isAutoRenewing = true,
            quantity = 1,
            message = "",
            originalJson = "{}"
        )
        assertTrue(result.success)
        assertEquals("noctua.sub.1", result.productId)
        assertEquals("GPA.1234", result.orderId)
        assertEquals("token123", result.purchaseToken)
        assertEquals(1700000000L, result.purchaseTime)
        assertTrue(result.isAcknowledged)
        assertTrue(result.isAutoRenewing)
    }

    // -----------------------------------------------
    // NoctuaProductPurchaseStatus
    // -----------------------------------------------

    @Test
    fun `NoctuaProductPurchaseStatus defaults are correct`() {
        val status = NoctuaProductPurchaseStatus(
            productId = "test.product",
            isPurchased = false
        )
        assertFalse(status.isAcknowledged)
        assertFalse(status.isAutoRenewing)
        assertEquals(PurchaseState.UNSPECIFIED, status.purchaseState)
        assertEquals("", status.purchaseToken)
        assertEquals(0L, status.purchaseTime)
        assertNull(status.orderId)
        assertEquals("", status.originalJson)
    }

    @Test
    fun `NoctuaProductPurchaseStatus for active subscription`() {
        val status = NoctuaProductPurchaseStatus(
            productId = "noctua.sub.1",
            isPurchased = true,
            isAcknowledged = true,
            isAutoRenewing = true,
            purchaseState = PurchaseState.PURCHASED,
            purchaseToken = "sub_token",
            purchaseTime = 1700000000L,
            orderId = "GPA.SUB.1234"
        )
        assertTrue(status.isPurchased)
        assertTrue(status.isAutoRenewing)
        assertTrue(status.isAcknowledged)
        assertEquals("noctua.sub.1", status.productId)
    }

    @Test
    fun `NoctuaProductPurchaseStatus for expired subscription`() {
        val status = NoctuaProductPurchaseStatus(
            productId = "noctua.sub.1",
            isPurchased = false
        )
        assertFalse(status.isPurchased)
        assertFalse(status.isAutoRenewing)
    }

    // -----------------------------------------------
    // NoctuaBillingConfig
    // -----------------------------------------------

    @Test
    fun `NoctuaBillingConfig has correct defaults`() {
        val config = NoctuaBillingConfig()
        assertTrue(config.enablePendingPurchases)
        assertTrue(config.enableAutoServiceReconnection)
        assertFalse(config.verifyPurchasesOnServer)
    }

    @Test
    fun `NoctuaBillingConfig custom values`() {
        val config = NoctuaBillingConfig(
            enablePendingPurchases = false,
            enableAutoServiceReconnection = false,
            verifyPurchasesOnServer = true
        )
        assertFalse(config.enablePendingPurchases)
        assertFalse(config.enableAutoServiceReconnection)
        assertTrue(config.verifyPurchasesOnServer)
    }

    // -----------------------------------------------
    // NoctuaProductDetails
    // -----------------------------------------------

    @Test
    fun `NoctuaProductDetails for INAPP product`() {
        val product = NoctuaProductDetails(
            productId = "noctua.test.android.pack1",
            title = "Pack 1",
            description = "Test pack",
            formattedPrice = "$0.99",
            priceAmountMicros = 990000L,
            priceCurrencyCode = "USD",
            productType = ProductType.INAPP
        )
        assertEquals("noctua.test.android.pack1", product.productId)
        assertEquals(ProductType.INAPP, product.productType)
        assertNull(product.offerToken)
        assertNull(product.subscriptionOfferDetails)
    }

    @Test
    fun `NoctuaProductDetails for SUBS product with offer details`() {
        val pricingPhase = NoctuaPricingPhase(
            formattedPrice = "$4.99",
            priceAmountMicros = 4990000L,
            priceCurrencyCode = "USD",
            billingPeriod = "P1M",
            recurrenceMode = 1
        )
        val offerDetails = NoctuaSubscriptionOfferDetails(
            basePlanId = "monthly",
            offerId = null,
            offerToken = "offer_token_123",
            pricingPhases = listOf(pricingPhase)
        )
        val product = NoctuaProductDetails(
            productId = "noctua.sub.1",
            title = "Monthly Sub",
            description = "Monthly subscription",
            formattedPrice = "$4.99",
            priceAmountMicros = 4990000L,
            priceCurrencyCode = "USD",
            productType = ProductType.SUBS,
            offerToken = "offer_token_123",
            subscriptionOfferDetails = listOf(offerDetails)
        )
        assertEquals(ProductType.SUBS, product.productType)
        assertNotNull(product.subscriptionOfferDetails)
        assertEquals(1, product.subscriptionOfferDetails!!.size)
        assertEquals("P1M", product.subscriptionOfferDetails!![0].pricingPhases[0].billingPeriod)
    }

    // -----------------------------------------------
    // ConsumableType & ProductType enums
    // -----------------------------------------------

    @Test
    fun `ConsumableType has all expected values`() {
        val types = ConsumableType.entries
        assertEquals(3, types.size)
        assertTrue(types.contains(ConsumableType.CONSUMABLE))
        assertTrue(types.contains(ConsumableType.NON_CONSUMABLE))
        assertTrue(types.contains(ConsumableType.SUBSCRIPTION))
    }

    @Test
    fun `ProductType has all expected values`() {
        val types = ProductType.entries
        assertEquals(2, types.size)
        assertTrue(types.contains(ProductType.INAPP))
        assertTrue(types.contains(ProductType.SUBS))
    }
}
