package com.noctuagames.sdk.presenter

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.noctuagames.labs.sdk.NoctuaInternal
import com.noctuagames.labs.sdk.utils.AppContext
import com.noctuagames.labs.sdk.utils.initKoinManually
import com.noctuagames.sdk.models.Account
import com.noctuagames.sdk.models.BillingErrorCode
import com.noctuagames.sdk.models.ConsumableType
import com.noctuagames.sdk.models.NoctuaAdjustAttribution
import com.noctuagames.sdk.models.NoctuaBillingConfig
import com.noctuagames.sdk.models.NoctuaConfig
import com.noctuagames.sdk.models.NoctuaProductDetails
import com.noctuagames.sdk.models.NoctuaProductPurchaseStatus
import com.noctuagames.sdk.models.NoctuaPurchaseResult
import com.noctuagames.sdk.models.ProductType
import com.noctuagames.sdk.models.toJsonString
import com.noctuagames.sdk.repositories.AccountRepository
import com.noctuagames.sdk.services.AdjustService
import com.noctuagames.sdk.services.BillingService
import com.noctuagames.sdk.services.BillingEventListener
import com.noctuagames.sdk.services.FacebookService
import com.noctuagames.sdk.services.FirebaseService
import com.noctuagames.sdk.utils.loadConfig
import kotlinx.coroutines.*

class NoctuaPresenter(
    context: Context,
    private val publishedApps: List<String>,
    private val billingConfig: NoctuaBillingConfig = NoctuaBillingConfig()
) {

    private val TAG = "NoctuaPresenter"

    private val appContext = context.applicationContext
    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val adjust: AdjustService?
    private val firebase: FirebaseService?
    private val facebook: FacebookService?
    private val billing: BillingService
    private val accounts: AccountRepository

    private var nativeInternalTrackerEnabled: Boolean = false
    private var noctuaAdjustAttribution: NoctuaAdjustAttribution? = null
    private var adjustAttribution: String = ""
    
    // Billing callbacks
    private var billingPurchaseCallback: ((NoctuaPurchaseResult) -> Unit)? = null
    private var billingProductDetailsCallback: ((List<NoctuaProductDetails>) -> Unit)? = null
    private var billingQueryPurchasesCallback: ((List<NoctuaPurchaseResult>) -> Unit)? = null
    private var billingRestorePurchasesCallback: ((List<NoctuaPurchaseResult>) -> Unit)? = null
    private var billingProductPurchaseStatusCallback: ((NoctuaProductPurchaseStatus) -> Unit)? = null
    private var billingServerVerificationCallback: ((NoctuaPurchaseResult, ConsumableType) -> Unit)? = null

    init {
        AppContext.set(appContext)
        val config = loadConfig(appContext)

        if (config.clientId.isNullOrEmpty()) {
            throw IllegalArgumentException("clientId is not set")
        }

        nativeInternalTrackerEnabled =
            config.noctua?.nativeInternalTrackerEnabled ?: false

        adjust = createAdjust(config)
        firebase = createFirebase(config)
        facebook = createFacebook(config)
        billing = createBilling()

        accounts = AccountRepository(appContext)

        coroutineScope.launch {
            accounts.syncOtherAccounts()
        }

        Log.i(TAG, "NoctuaPresenter initialized")
    }

    // ------------------------------------
    // Initialization
    // ------------------------------------

    fun initKoin() {
        initKoinManually(appContext)
    }

    // ------------------------------------
    // Lifecycle
    // ------------------------------------

    fun onResume() {
        adjust?.onResume()

        if (nativeInternalTrackerEnabled) {
            NoctuaInternal.onInternalNoctuaApplicationPause(false)
        }

        coroutineScope.launch {
            accounts.syncOtherAccounts()
        }
    }

    fun onPause() {
        adjust?.onPause()

        if (nativeInternalTrackerEnabled) {
            NoctuaInternal.onInternalNoctuaApplicationPause(true)
        }
    }

    fun onDestroy() {
        if (nativeInternalTrackerEnabled) {
            NoctuaInternal.onInternalNoctuaDispose()
        }
    }

    fun onOnline() = adjust?.onOnline()
    fun onOffline() = adjust?.onOffline()

    // ------------------------------------
    // Tracking
    // ------------------------------------

    fun trackAdRevenue(
        source: String,
        revenue: Double,
        currency: String,
        extraPayload: MutableMap<String, Any>
    ) {
        if (source.isEmpty() || revenue <= 0 || currency.isEmpty()) {
            Log.e(TAG, "Invalid ad revenue parameters")
            return
        }

        adjust?.trackAdRevenue(source, revenue, currency, extraPayload)
        firebase?.trackAdRevenue(source, revenue, currency, extraPayload)
        facebook?.trackAdRevenue(source, revenue, currency, extraPayload)
    }

    fun trackPurchase(
        orderId: String,
        amount: Double,
        currency: String,
        extraPayload: MutableMap<String, Any>
    ) {
        if (orderId.isEmpty() || amount <= 0 || currency.isEmpty()) {
            Log.e(TAG, "Invalid purchase parameters")
            return
        }

        adjust?.trackPurchase(orderId, amount, currency, extraPayload)
        firebase?.trackPurchase(orderId, amount, currency, extraPayload)
        facebook?.trackPurchase(orderId, amount, currency, extraPayload)
    }

    fun trackCustomEvent(
        eventName: String,
        payload: MutableMap<String, Any>
    ) {
        adjust?.trackCustomEvent(eventName, payload)
        firebase?.trackCustomEvent(eventName, payload)
        facebook?.trackCustomEvent(eventName, payload)

        if (nativeInternalTrackerEnabled) {
            NoctuaInternal.trackCustomEvent(eventName, payload)
        }
    }

    fun trackCustomEventWithRevenue(
        eventName: String,
        revenue: Double,
        currency: String,
        payload: MutableMap<String, Any>
    ) {
        adjust?.trackCustomEventWithRevenue(eventName, revenue, currency, payload)
        firebase?.trackCustomEventWithRevenue(eventName, revenue, currency, payload)
        facebook?.trackCustomEventWithRevenue(eventName, revenue, currency, payload)
    }

    // ------------------------------------
    // Firebase IDs
    // ------------------------------------

    fun getFirebaseInstallationID(onResult: (String) -> Unit) {
        firebase?.getFirebaseInstallationID { id ->
            onResult(id)
        } ?: onResult("")
    }

    fun getFirebaseAnalyticsSessionID(onResult: (String) -> Unit) {
        firebase?.getFirebaseAnalyticsSessionID { id ->
            onResult(id)
        } ?: onResult("")
    }

    // ------------------------------------
    // Remote Config
    // ------------------------------------

    fun getFirebaseRemoteConfigString(key: String): String? {
        return firebase?.getFirebaseRemoteConfigString(key)
    }

    fun getFirebaseRemoteConfigBoolean(key: String): Boolean? {
        return firebase?.getFirebaseRemoteConfigBoolean(key)
    }

    fun getFirebaseRemoteConfigDouble(key: String): Double? {
        return firebase?.getFirebaseRemoteConfigDouble(key)
    }

    fun getFirebaseRemoteConfigLong(key: String): Long? {
        return firebase?.getFirebaseRemoteConfigLong(key)
    }

    // ------------------------------------
    // Accounts
    // ------------------------------------

    fun getAccounts(): List<Account> = accounts.getAll()

    fun getAccount(userId: Long, gameId: Long): Account? =
        accounts.getSingle(userId, gameId)

    fun getAccountsByUserId(userId: Long): List<Account> =
        accounts.getByUserId(userId)

    fun putAccount(account: Account) {
        accounts.put(account)
    }

    fun deleteAccount(account: Account): Int =
        accounts.delete(account.userId, account.gameId)

    // ------------------------------------
    // Attribution
    // ------------------------------------

    fun getAdjustAttribution(onResult: (String) -> Unit) {
        if (adjustAttribution.isNotEmpty()) {
            onResult(adjustAttribution)
            return
        }

        adjust?.getAdjustCurrentAttributionJson { attribution ->
            adjustAttribution = attribution
            onResult(attribution)
        } ?: onResult("")
    }

    // ------------------------------------
    // Notification Permission
    // ------------------------------------

    fun askNotificationPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            Log.d(TAG, "Notification permission auto-granted (< Android 13)")
            return
        }

        val permission = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.POST_NOTIFICATIONS
        )

        if (permission == PackageManager.PERMISSION_GRANTED) {
            Log.d(TAG, "Notification permission already granted")
            return
        }

        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            1001
        )
    }

    // ------------------------------------
    // Internal Tracker Configuration
    // ------------------------------------

    fun setSessionExtraParams(extraParams: Map<String, Any>) {
        if (nativeInternalTrackerEnabled) {
            NoctuaInternal.setSessionExtraParams(extraParams)
        }
    }

    fun setSessionTag(tag: String) {
        if (nativeInternalTrackerEnabled) {
            NoctuaInternal.setSessionTag(tag)
        }
    }

    fun getSessionTag() : String {
        if (nativeInternalTrackerEnabled) {
            return NoctuaInternal.getSessionTag()
        }
        return ""
    }

    fun setExperiment(experiment: String) {
        if (nativeInternalTrackerEnabled) {
            NoctuaInternal.setExperiment(experiment)
        }
    }

    fun getExperiment() : String {
        if (nativeInternalTrackerEnabled) {
            return NoctuaInternal.getExperiment()
        }
        return ""
    }

    fun setGeneralExperiment(experiment: String) {
        if (nativeInternalTrackerEnabled) {
            NoctuaInternal.setGeneralExperiment(experiment)
        }
    }

    fun getGeneralExperiment(experimentKey: String) : String{
        if (nativeInternalTrackerEnabled) {
            return NoctuaInternal.getGeneralExperiment(experimentKey)
        }
        return ""
    }

    // ------------------------------------
    // Events Local Storage
    // ------------------------------------

    fun saveEvents(jsonString: String) {
        NoctuaInternal.saveExternalEvents(jsonString)
    }

    fun getEvents(onResult: (List<String>) -> Unit)  {
        NoctuaInternal.getExternalEvents { events ->
            onResult(events)
        }
    }

    fun deleteEvents() {
        NoctuaInternal.deleteExternalEvents()
    }

    // ------------------------------------
    // Events Per-Row Storage (Unlimited)
    // ------------------------------------

    fun insertEvent(eventJson: String) {
        NoctuaInternal.insertExternalEvent(eventJson)
    }

    fun getEventsBatch(limit: Int, offset: Int, onResult: (String) -> Unit) {
        NoctuaInternal.getExternalEventsBatch(limit, offset, onResult)
    }

    fun deleteEventsByIds(idsJson: String, onResult: (Int) -> Unit) {
        NoctuaInternal.deleteExternalEventsByIds(idsJson, onResult)
    }

    fun getEventCount(onResult: (Int) -> Unit) {
        NoctuaInternal.getExternalEventCount(onResult)
    }

    // ------------------------------------
    // Billing / In-App Purchases
    // ------------------------------------

    fun initializeBilling(
        onPurchaseCompleted: ((NoctuaPurchaseResult) -> Unit)? = null,
        onPurchaseUpdated: ((NoctuaPurchaseResult) -> Unit)? = null,
        onProductDetailsLoaded: ((List<NoctuaProductDetails>) -> Unit)? = null,
        onQueryPurchasesCompleted: ((List<NoctuaPurchaseResult>) -> Unit)? = null,
        onRestorePurchasesCompleted: ((List<NoctuaPurchaseResult>) -> Unit)? = null,
        onProductPurchaseStatusResult: ((NoctuaProductPurchaseStatus) -> Unit)? = null,
        onServerVerificationRequired: ((NoctuaPurchaseResult, ConsumableType) -> Unit)? = null,
        onBillingError: ((BillingErrorCode, String) -> Unit)? = null
    ) {
        billingPurchaseCallback = onPurchaseCompleted
        billingProductDetailsCallback = onProductDetailsLoaded
        billingQueryPurchasesCallback = onQueryPurchasesCompleted
        billingRestorePurchasesCallback = onRestorePurchasesCompleted
        billingProductPurchaseStatusCallback = onProductPurchaseStatusResult
        billingServerVerificationCallback = onServerVerificationRequired

        billing.initialize(object : BillingEventListener {
            override fun onPurchaseCompleted(result: NoctuaPurchaseResult) {
                billingPurchaseCallback?.invoke(result)
            }

            override fun onPurchaseUpdated(result: NoctuaPurchaseResult) {
                onPurchaseUpdated?.invoke(result)
            }

            override fun onProductDetailsLoaded(products: List<NoctuaProductDetails>) {
                billingProductDetailsCallback?.invoke(products)
            }

            override fun onQueryPurchasesCompleted(purchases: List<NoctuaPurchaseResult>) {
                billingQueryPurchasesCallback?.invoke(purchases)
            }

            override fun onRestorePurchasesCompleted(purchases: List<NoctuaPurchaseResult>) {
                billingRestorePurchasesCallback?.invoke(purchases)
            }

            override fun onProductPurchaseStatusResult(status: NoctuaProductPurchaseStatus) {
                billingProductPurchaseStatusCallback?.invoke(status)
            }

            override fun onServerVerificationRequired(result: NoctuaPurchaseResult, consumableType: ConsumableType) {
                billingServerVerificationCallback?.invoke(result, consumableType)
            }

            override fun onBillingError(error: BillingErrorCode, message: String) {
                Log.e(TAG, "Billing error: $error - $message")
                onBillingError?.invoke(error, message)
            }
        })
    }

    fun registerProduct(productId: String, consumableType: ConsumableType) {
        billing.registerProduct(productId, consumableType)
    }

    fun queryProductDetails(productIds: List<String>, productType: ProductType = ProductType.INAPP) {
        billing.queryProductDetails(productIds, productType)
    }

    fun launchBillingFlow(activity: Activity, productDetails: NoctuaProductDetails) {
        billing.launchBillingFlow(activity, productDetails)
    }

    fun queryPurchases(productType: ProductType = ProductType.INAPP) {
        billing.queryPurchases(productType)
    }

    fun acknowledgePurchase(purchaseToken: String, callback: ((Boolean) -> Unit)? = null) {
        billing.acknowledgePurchase(purchaseToken, callback)
    }

    fun consumePurchase(purchaseToken: String, callback: ((Boolean) -> Unit)? = null) {
        billing.consumePurchase(purchaseToken, callback)
    }

    fun restorePurchases() {
        billing.restorePurchases()
    }

    fun getProductPurchaseStatus(productId: String) {
        billing.getProductPurchaseStatus(productId)
    }

    fun completePurchaseProcessing(
        purchaseToken: String,
        consumableType: ConsumableType,
        verified: Boolean,
        callback: ((Boolean) -> Unit)? = null
    ) {
        billing.completePurchaseProcessing(purchaseToken, consumableType, verified, callback)
    }

    fun reconnectBilling() {
        billing.reconnect()
    }

    fun disposeBilling() {
        billing.dispose()
    }

    fun isBillingReady(): Boolean = billing.isReady()

    // ------------------------------------
    // Private SDK Initialization
    // ------------------------------------

    private fun createBilling(): BillingService {
        return BillingService(appContext, billingConfig)
    }

    private fun createAdjust(config: NoctuaConfig): AdjustService? =
        try {
            config.adjust?.android?.let {
                AdjustService(it, appContext) { attribution ->
                    noctuaAdjustAttribution = attribution
                    adjustAttribution = attribution.toJsonString()
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Adjust init failed: ${e.message}")
            null
        }

    private fun createFirebase(config: NoctuaConfig): FirebaseService? =
        try {
            config.firebase?.android?.let {
                FirebaseService(it, appContext)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Firebase init failed: ${e.message}")
            null
        }

    private fun createFacebook(config: NoctuaConfig): FacebookService? =
        try {
            config.facebook?.android?.let {
                FacebookService(it, appContext)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Facebook init failed: ${e.message}")
            null
        }
}
