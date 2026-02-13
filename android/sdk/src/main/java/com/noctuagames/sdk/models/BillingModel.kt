package com.noctuagames.sdk.models

enum class BillingErrorCode(val code: Int) {
    OK(0),
    USER_CANCELED(1),
    SERVICE_UNAVAILABLE(2),
    BILLING_UNAVAILABLE(3),
    ITEM_UNAVAILABLE(4),
    DEVELOPER_ERROR(5),
    ERROR(6),
    ITEM_ALREADY_OWNED(7),
    ITEM_NOT_OWNED(8),
    NETWORK_ERROR(12),
    SERVICE_DISCONNECTED(-1),
    FEATURE_NOT_SUPPORTED(-2);

    companion object {
        fun fromCode(code: Int): BillingErrorCode = entries.find { it.code == code } ?: ERROR
    }
}

enum class PurchaseState(val state: Int) {
    UNSPECIFIED(0),
    PURCHASED(1),
    PENDING(2);

    companion object {
        fun fromState(state: Int): PurchaseState = entries.find { it.state == state } ?: UNSPECIFIED
    }
}

enum class ProductType {
    INAPP,      // One-time product (consumable or non-consumable)
    SUBS        // Subscription
}

enum class ConsumableType {
    CONSUMABLE,      // Can be purchased multiple times (e.g., coins, gems)
    NON_CONSUMABLE,  // Purchased once (e.g., premium unlock, remove ads)
    SUBSCRIPTION     // Auto-renewing subscription
}

data class NoctuaProductDetails(
    val productId: String,
    val title: String,
    val description: String,
    val formattedPrice: String,
    val priceAmountMicros: Long,
    val priceCurrencyCode: String,
    val productType: ProductType,
    val offerToken: String? = null,
    val subscriptionOfferDetails: List<NoctuaSubscriptionOfferDetails>? = null
)

data class NoctuaSubscriptionOfferDetails(
    val basePlanId: String,
    val offerId: String?,
    val offerToken: String,
    val pricingPhases: List<NoctuaPricingPhase>
)

data class NoctuaPricingPhase(
    val formattedPrice: String,
    val priceAmountMicros: Long,
    val priceCurrencyCode: String,
    val billingPeriod: String,  // P1M, P1Y, etc.
    val recurrenceMode: Int
)

data class NoctuaPurchaseResult(
    val success: Boolean,
    val errorCode: BillingErrorCode = BillingErrorCode.OK,
    val purchaseState: PurchaseState = PurchaseState.UNSPECIFIED,
    val productId: String = "",
    val orderId: String? = null,
    val purchaseToken: String = "",
    val purchaseTime: Long = 0,
    val isAcknowledged: Boolean = false,
    val isAutoRenewing: Boolean = false,
    val quantity: Int = 1,
    val message: String = "",
    val originalJson: String = ""
) {
    fun isPending(): Boolean = purchaseState == PurchaseState.PENDING
    fun isPurchased(): Boolean = purchaseState == PurchaseState.PURCHASED
}

/**
 * Represents the purchase status of a specific product.
 */
data class NoctuaProductPurchaseStatus(
    val productId: String,
    val isPurchased: Boolean,
    val isAcknowledged: Boolean = false,
    val isAutoRenewing: Boolean = false,
    val purchaseState: PurchaseState = PurchaseState.UNSPECIFIED,
    val purchaseToken: String = "",
    val purchaseTime: Long = 0,
    val orderId: String? = null,
    val originalJson: String = ""
)

// Configuration for billing
data class NoctuaBillingConfig(
    val enablePendingPurchases: Boolean = true,
    val enableAutoServiceReconnection: Boolean = true,
    val verifyPurchasesOnServer: Boolean = false
)