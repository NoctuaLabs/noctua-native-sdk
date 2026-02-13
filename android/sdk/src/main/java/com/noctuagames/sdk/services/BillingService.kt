package com.noctuagames.sdk.services

import android.app.Activity
import android.content.Context
import android.util.Log
import com.android.billingclient.api.*
import com.google.common.collect.ImmutableList
import com.noctuagames.sdk.models.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.util.concurrent.ConcurrentHashMap

interface BillingEventListener {
    fun onPurchaseCompleted(result: NoctuaPurchaseResult)
    fun onPurchaseUpdated(result: NoctuaPurchaseResult)
    fun onProductDetailsLoaded(products: List<NoctuaProductDetails>)
    fun onQueryPurchasesCompleted(purchases: List<NoctuaPurchaseResult>)
    fun onRestorePurchasesCompleted(purchases: List<NoctuaPurchaseResult>)
    fun onProductPurchaseStatusResult(status: NoctuaProductPurchaseStatus)

    /**
     * Called when a purchase requires server verification before being acknowledged/consumed.
     *
     * The integrator must verify the purchase on their server and then call [com.noctuagames.sdk.Noctua.completePurchaseProcessing]
     * with the result to proceed with acknowledgement or consumption.
     *
     * @param result The purchase that requires verification.
     * @param consumableType The consumable type of the product.
     */
    fun onServerVerificationRequired(result: NoctuaPurchaseResult, consumableType: ConsumableType)

    fun onBillingError(error: BillingErrorCode, message: String)
}

class BillingService(
    private val context: Context,
    private val config: NoctuaBillingConfig = NoctuaBillingConfig()
) {
    private val TAG = "BillingService"
    private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val ioScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private var billingClient: BillingClient? = null
    private var eventListener: BillingEventListener? = null
    private var isInitialized = false

    // Track connection state
    private val _connectionState = MutableStateFlow(false)
    val connectionState: StateFlow<Boolean> = _connectionState

    // Product type mapping
    private val productTypeMap = ConcurrentHashMap<String, ConsumableType>()

    fun initialize(listener: BillingEventListener? = null) {
        if (isInitialized) {
            Log.w(TAG, "BillingService already initialized")
            return
        }

        this.eventListener = listener

        val builder = BillingClient.newBuilder(context)
            .setListener(PurchasesUpdatedListenerImpl())
            .enablePendingPurchases(
                PendingPurchasesParams.newBuilder()
                    .enablePrepaidPlans()
                    .enableOneTimeProducts()
                    .build()
            )

        if (config.enableAutoServiceReconnection) {
            builder.enableAutoServiceReconnection()
        }

        billingClient = builder.build()
        startConnection()
        isInitialized = true
        Log.i(TAG, "BillingService initialized")
    }

    private fun startConnection() {
        billingClient?.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    Log.i(TAG, "Billing client connected successfully")
                    _connectionState.value = true
                    // Query existing purchases on connection
                    queryExistingPurchases()
                } else {
                    Log.e(TAG, "Billing setup failed: ${billingResult.debugMessage}")
                    _connectionState.value = false
                    eventListener?.onBillingError(
                        BillingErrorCode.fromCode(billingResult.responseCode),
                        billingResult.debugMessage
                    )
                }
            }

            override fun onBillingServiceDisconnected() {
                Log.w(TAG, "Billing service disconnected")
                _connectionState.value = false
                // Auto-reconnection is handled by BillingClient if enabled
            }
        })
    }

    fun reconnect() {
        if (billingClient?.isReady == false) {
            startConnection()
        }
    }

    fun dispose() {
        mainScope.cancel()
        ioScope.cancel()
        billingClient?.endConnection()
        isInitialized = false
        Log.i(TAG, "BillingService disposed")
    }

    fun registerProduct(productId: String, consumableType: ConsumableType) {
        productTypeMap[productId] = consumableType
        Log.d(TAG, "Registered product: $productId as $consumableType")
    }

    fun queryProductDetails(productIds: List<String>, productType: ProductType = ProductType.INAPP) {
        if (!isReady()) {
            eventListener?.onBillingError(BillingErrorCode.SERVICE_DISCONNECTED, "Billing client not ready")
            return
        }

        val products = productIds.map { productId ->
            QueryProductDetailsParams.Product.newBuilder()
                .setProductId(productId)
                .setProductType(
                    when (productType) {
                        ProductType.INAPP -> BillingClient.ProductType.INAPP
                        ProductType.SUBS -> BillingClient.ProductType.SUBS
                    }
                )
                .build()
        }

        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(ImmutableList.copyOf(products))
            .build()

        billingClient?.queryProductDetailsAsync(params) { billingResult, result ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val productDetailsList = result.productDetailsList
                val results = productDetailsList.map { details ->
                    parseProductDetails(details)
                }

                Log.d(TAG, "Loaded ${results.size} product details")
                eventListener?.onProductDetailsLoaded(results)
            } else {
                Log.e(TAG, "Failed to query product details: ${billingResult.debugMessage}")
                eventListener?.onBillingError(
                    BillingErrorCode.fromCode(billingResult.responseCode),
                    billingResult.debugMessage
                )
            }
        }
    }

    fun launchBillingFlow(activity: Activity, noctuaProductDetails: NoctuaProductDetails) {
        if (!isReady()) {
            eventListener?.onBillingError(BillingErrorCode.SERVICE_DISCONNECTED, "Billing client not ready")
            return
        }

        // Query product details first to get the actual ProductDetails object
        val product = QueryProductDetailsParams.Product.newBuilder()
            .setProductId(noctuaProductDetails.productId)
            .setProductType(
                when (noctuaProductDetails.productType) {
                    ProductType.INAPP -> BillingClient.ProductType.INAPP
                    ProductType.SUBS -> BillingClient.ProductType.SUBS
                }
            )
            .build()

        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(ImmutableList.of(product))
            .build()

        billingClient?.queryProductDetailsAsync(params) { billingResult, result ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val productDetailsList = result.productDetailsList
                if (productDetailsList.isNotEmpty()) {
                    val details = productDetailsList[0]
                    launchBillingFlowInternal(activity, details)
                } else {
                    eventListener?.onBillingError(
                        BillingErrorCode.ITEM_UNAVAILABLE,
                        "Product not found"
                    )
                }
            } else {
                eventListener?.onBillingError(
                    BillingErrorCode.fromCode(billingResult.responseCode),
                    billingResult.debugMessage
                )
            }
        }
    }

    private fun launchBillingFlowInternal(activity: Activity, productDetails: ProductDetails) {
        val productDetailsParams = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(productDetails)
            .apply {
                // For subscriptions, we need offer token
                if (productDetails.productType == BillingClient.ProductType.SUBS) {
                    val offerToken = productDetails.subscriptionOfferDetails?.firstOrNull()?.offerToken
                    offerToken?.let { setOfferToken(it) }
                }

                if (productDetails.productType == BillingClient.ProductType.INAPP) {
                    val offerToken = productDetails.oneTimePurchaseOfferDetails?.offerToken
                    offerToken?.let { setOfferToken(it) }
                }
            }
            .build()

        val billingFlowParams = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(ImmutableList.of(productDetailsParams))
            .build()

        val result = billingClient?.launchBillingFlow(activity, billingFlowParams)
        if (result?.responseCode != BillingClient.BillingResponseCode.OK) {
            Log.e(TAG, "Failed to launch billing flow: ${result?.debugMessage}")
            eventListener?.onBillingError(
                BillingErrorCode.fromCode(result?.responseCode ?: BillingClient.BillingResponseCode.ERROR),
                result?.debugMessage ?: "Unknown error"
            )
        }
    }

    fun queryPurchases(productType: ProductType = ProductType.INAPP) {
        if (!isReady()) {
            eventListener?.onBillingError(BillingErrorCode.SERVICE_DISCONNECTED, "Billing client not ready")
            return
        }

        val params = QueryPurchasesParams.newBuilder()
            .setProductType(
                when (productType) {
                    ProductType.INAPP -> BillingClient.ProductType.INAPP
                    ProductType.SUBS -> BillingClient.ProductType.SUBS
                }
            )
            .build()

        billingClient?.queryPurchasesAsync(params) { billingResult, purchasesList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val results = purchasesList.map { purchase ->
                    parsePurchase(purchase)
                }

                Log.d(TAG, "Queried ${results.size} purchases")
                eventListener?.onQueryPurchasesCompleted(results)
            } else {
                Log.e(TAG, "Failed to query purchases: ${billingResult.debugMessage}")
                eventListener?.onBillingError(
                    BillingErrorCode.fromCode(billingResult.responseCode),
                    billingResult.debugMessage
                )
            }
        }
    }

    fun queryExistingPurchases() {
        queryPurchases(ProductType.INAPP)
        queryPurchases(ProductType.SUBS)
    }

    fun acknowledgePurchase(purchaseToken: String, callback: ((Boolean) -> Unit)? = null) {
        if (!isReady()) {
            callback?.invoke(false)
            return
        }

        val params = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchaseToken)
            .build()

        billingClient?.acknowledgePurchase(params) { billingResult ->
            val success = billingResult.responseCode == BillingClient.BillingResponseCode.OK
            if (success) {
                Log.d(TAG, "Purchase acknowledged: $purchaseToken")
            } else {
                Log.e(TAG, "Failed to acknowledge purchase: ${billingResult.debugMessage}")
            }
            callback?.invoke(success)
        }
    }

    fun consumePurchase(purchaseToken: String, callback: ((Boolean) -> Unit)? = null) {
        if (!isReady()) {
            callback?.invoke(false)
            return
        }

        val params = ConsumeParams.newBuilder()
            .setPurchaseToken(purchaseToken)
            .build()

        billingClient?.consumeAsync(params) { billingResult, _ ->
            val success = billingResult.responseCode == BillingClient.BillingResponseCode.OK
            if (success) {
                Log.d(TAG, "Purchase consumed: $purchaseToken")
            } else {
                Log.e(TAG, "Failed to consume purchase: ${billingResult.debugMessage}")
            }
            callback?.invoke(success)
        }
    }

    /**
     * Restores all purchases by querying both INAPP and SUBS purchases.
     * Unacknowledged purchases are automatically processed (acknowledged or consumed)
     * based on their registered consumable type.
     */
    fun restorePurchases() {
        if (!isReady()) {
            eventListener?.onBillingError(BillingErrorCode.SERVICE_DISCONNECTED, "Billing client not ready")
            return
        }

        val allPurchases = mutableListOf<NoctuaPurchaseResult>()
        var queriesCompleted = 0
        val totalQueries = 2

        fun onQueryDone() {
            queriesCompleted++
            if (queriesCompleted >= totalQueries) {
                Log.d(TAG, "Restore purchases completed: ${allPurchases.size} purchases found")

                // Process unacknowledged purchases
                for (purchase in allPurchases) {
                    if (purchase.isPurchased() && !purchase.isAcknowledged) {
                        val consumableType = productTypeMap[purchase.productId] ?: ConsumableType.NON_CONSUMABLE
                        ioScope.launch {
                            when (consumableType) {
                                ConsumableType.CONSUMABLE -> consumePurchase(purchase.purchaseToken)
                                ConsumableType.NON_CONSUMABLE, ConsumableType.SUBSCRIPTION ->
                                    acknowledgePurchase(purchase.purchaseToken)
                            }
                        }
                    }
                }

                eventListener?.onRestorePurchasesCompleted(allPurchases)
            }
        }

        // Query INAPP purchases
        val inappParams = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.INAPP)
            .build()

        billingClient?.queryPurchasesAsync(inappParams) { billingResult, purchasesList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val results = purchasesList.map { parsePurchase(it) }
                synchronized(allPurchases) { allPurchases.addAll(results) }
            } else {
                Log.e(TAG, "Failed to query INAPP purchases for restore: ${billingResult.debugMessage}")
            }
            onQueryDone()
        }

        // Query SUBS purchases
        val subsParams = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.SUBS)
            .build()

        billingClient?.queryPurchasesAsync(subsParams) { billingResult, purchasesList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val results = purchasesList.map { parsePurchase(it) }
                synchronized(allPurchases) { allPurchases.addAll(results) }
            } else {
                Log.e(TAG, "Failed to query SUBS purchases for restore: ${billingResult.debugMessage}")
            }
            onQueryDone()
        }
    }

    /**
     * Checks the purchase status of a specific product by querying both INAPP and SUBS.
     *
     * @param productId The product ID to check.
     */
    fun getProductPurchaseStatus(productId: String) {
        if (!isReady()) {
            eventListener?.onBillingError(BillingErrorCode.SERVICE_DISCONNECTED, "Billing client not ready")
            return
        }

        val allPurchases = mutableListOf<NoctuaPurchaseResult>()
        var queriesCompleted = 0
        val totalQueries = 2

        fun onQueryDone() {
            queriesCompleted++
            if (queriesCompleted >= totalQueries) {
                val matchingPurchase = allPurchases.find { it.productId == productId }

                val status = if (matchingPurchase != null) {
                    NoctuaProductPurchaseStatus(
                        productId = productId,
                        isPurchased = matchingPurchase.isPurchased(),
                        isAcknowledged = matchingPurchase.isAcknowledged,
                        isAutoRenewing = matchingPurchase.isAutoRenewing,
                        purchaseState = matchingPurchase.purchaseState,
                        purchaseToken = matchingPurchase.purchaseToken,
                        purchaseTime = matchingPurchase.purchaseTime,
                        orderId = matchingPurchase.orderId,
                        originalJson = matchingPurchase.originalJson
                    )
                } else {
                    NoctuaProductPurchaseStatus(
                        productId = productId,
                        isPurchased = false
                    )
                }

                Log.d(TAG, "Product purchase status for $productId: isPurchased=${status.isPurchased}")
                eventListener?.onProductPurchaseStatusResult(status)
            }
        }

        // Query INAPP purchases
        val inappParams = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.INAPP)
            .build()

        billingClient?.queryPurchasesAsync(inappParams) { billingResult, purchasesList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val results = purchasesList.map { parsePurchase(it) }
                synchronized(allPurchases) { allPurchases.addAll(results) }
            }
            onQueryDone()
        }

        // Query SUBS purchases
        val subsParams = QueryPurchasesParams.newBuilder()
            .setProductType(BillingClient.ProductType.SUBS)
            .build()

        billingClient?.queryPurchasesAsync(subsParams) { billingResult, purchasesList ->
            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                val results = purchasesList.map { parsePurchase(it) }
                synchronized(allPurchases) { allPurchases.addAll(results) }
            }
            onQueryDone()
        }
    }

    fun isReady(): Boolean = billingClient?.isReady == true && _connectionState.value

    private fun parseProductDetails(details: ProductDetails): NoctuaProductDetails {
        val offerDetails = details.oneTimePurchaseOfferDetails
        val subscriptionOffers = details.subscriptionOfferDetails

        return NoctuaProductDetails(
            productId = details.productId,
            title = details.title,
            description = details.description,
            formattedPrice = offerDetails?.formattedPrice ?: subscriptionOffers?.firstOrNull()?.pricingPhases?.pricingPhaseList?.firstOrNull()?.formattedPrice ?: "",
            priceAmountMicros = offerDetails?.priceAmountMicros ?: subscriptionOffers?.firstOrNull()?.pricingPhases?.pricingPhaseList?.firstOrNull()?.priceAmountMicros ?: 0,
            priceCurrencyCode = offerDetails?.priceCurrencyCode ?: subscriptionOffers?.firstOrNull()?.pricingPhases?.pricingPhaseList?.firstOrNull()?.priceCurrencyCode ?: "",
            productType = if (details.productType == BillingClient.ProductType.INAPP) ProductType.INAPP else ProductType.SUBS,
            offerToken = subscriptionOffers?.firstOrNull()?.offerToken,
            subscriptionOfferDetails = subscriptionOffers?.map { offer ->
                NoctuaSubscriptionOfferDetails(
                    basePlanId = offer.basePlanId,
                    offerId = offer.offerId,
                    offerToken = offer.offerToken,
                    pricingPhases = offer.pricingPhases.pricingPhaseList.map { phase ->
                        NoctuaPricingPhase(
                            formattedPrice = phase.formattedPrice,
                            priceAmountMicros = phase.priceAmountMicros,
                            priceCurrencyCode = phase.priceCurrencyCode,
                            billingPeriod = phase.billingPeriod,
                            recurrenceMode = phase.recurrenceMode
                        )
                    }
                )
            }
        )
    }

    private fun parsePurchase(purchase: Purchase): NoctuaPurchaseResult {
        return NoctuaPurchaseResult(
            success = purchase.purchaseState == Purchase.PurchaseState.PURCHASED,
            errorCode = BillingErrorCode.OK,
            purchaseState = when (purchase.purchaseState) {
                Purchase.PurchaseState.PURCHASED -> PurchaseState.PURCHASED
                Purchase.PurchaseState.PENDING -> PurchaseState.PENDING
                else -> PurchaseState.UNSPECIFIED
            },
            productId = purchase.products.firstOrNull() ?: "",
            orderId = purchase.orderId,
            purchaseToken = purchase.purchaseToken,
            purchaseTime = purchase.purchaseTime,
            isAcknowledged = purchase.isAcknowledged,
            isAutoRenewing = purchase.isAutoRenewing,
            quantity = purchase.quantity,
            originalJson = purchase.originalJson
        )
    }

    private inner class PurchasesUpdatedListenerImpl : PurchasesUpdatedListener {
        override fun onPurchasesUpdated(billingResult: BillingResult, purchases: MutableList<Purchase>?) {
            val errorCode = BillingErrorCode.fromCode(billingResult.responseCode)

            if (billingResult.responseCode == BillingClient.BillingResponseCode.OK && purchases != null) {
                for (purchase in purchases) {
                    val result = parsePurchase(purchase)
                    Log.d(TAG, "Purchase updated: ${result.productId}, state: ${result.purchaseState}")

                    // Auto-acknowledge or consume based on product type
                    handlePurchase(result, purchase)

                    eventListener?.onPurchaseUpdated(result)
                }
            } else {
                Log.e(TAG, "Purchase update failed: ${billingResult.debugMessage}")
                eventListener?.onBillingError(errorCode, billingResult.debugMessage)

                // Notify about failed purchase
                eventListener?.onPurchaseUpdated(
                    NoctuaPurchaseResult(
                        success = false,
                        errorCode = errorCode,
                        message = billingResult.debugMessage
                    )
                )
            }
        }
    }

    /**
     * Completes purchase processing after server verification.
     *
     * Call this method after your server has verified (and acknowledged) the purchase.
     * - For **consumables**: consumes the purchase client-side so it can be bought again.
     * - For **non-consumables / subscriptions**: no client-side action needed since
     *   the server already acknowledged the purchase via the Google Play Developer API.
     *
     * If [verified] is false, no action is taken.
     *
     * @param purchaseToken The purchase token that was verified.
     * @param consumableType The consumable type of the product.
     * @param verified Whether the server verification succeeded.
     * @param callback Optional callback with success status.
     */
    fun completePurchaseProcessing(
        purchaseToken: String,
        consumableType: ConsumableType,
        verified: Boolean,
        callback: ((Boolean) -> Unit)? = null
    ) {
        if (!verified) {
            Log.w(TAG, "Server verification failed for token: ${purchaseToken.take(20)}...")
            callback?.invoke(false)
            return
        }

        when (consumableType) {
            ConsumableType.CONSUMABLE -> {
                // Consumables must be consumed client-side to allow re-purchase
                if (!isReady()) {
                    eventListener?.onBillingError(BillingErrorCode.SERVICE_DISCONNECTED, "Billing client not ready")
                    callback?.invoke(false)
                    return
                }
                consumePurchase(purchaseToken, callback)
            }
            ConsumableType.NON_CONSUMABLE, ConsumableType.SUBSCRIPTION -> {
                // Server already acknowledged via Google Play Developer API, nothing to do client-side
                Log.d(TAG, "Purchase acknowledged by server, no client-side action needed")
                callback?.invoke(true)
            }
        }
    }

    private fun handlePurchase(result: NoctuaPurchaseResult, purchase: Purchase) {
        val productId = result.productId
        val consumableType = productTypeMap[productId] ?: ConsumableType.NON_CONSUMABLE

        if (result.isPurchased() && !result.isAcknowledged) {
            if (config.verifyPurchasesOnServer) {
                // Delegate to integrator for server verification
                Log.d(TAG, "Server verification required for $productId (type: $consumableType)")
                eventListener?.onServerVerificationRequired(result, consumableType)
            } else {
                // Process directly without server verification
                ioScope.launch {
                    when (consumableType) {
                        ConsumableType.CONSUMABLE -> consumePurchase(result.purchaseToken)
                        ConsumableType.NON_CONSUMABLE, ConsumableType.SUBSCRIPTION ->
                            acknowledgePurchase(result.purchaseToken)
                    }
                }
            }
        }
    }
}