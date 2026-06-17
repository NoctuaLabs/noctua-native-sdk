package com.noctuagames.sdk.presenter

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.noctuagames.sdk.utils.NoctuaLog
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
import com.noctuagames.sdk.services.AppManagementService
import com.noctuagames.sdk.services.BillingEventListener
import com.noctuagames.sdk.services.FacebookService
import com.noctuagames.sdk.services.FirebaseService
import com.noctuagames.sdk.utils.loadConfig
import kotlinx.coroutines.*

class NoctuaPresenter(
    context: Context,
    private val publishedApps: List<String>,
    private val billingConfig: NoctuaBillingConfig = NoctuaBillingConfig(),
    private val sandboxEnabledOverride: Boolean? = null
) {

    private val TAG = "NoctuaPresenter"

    private val appContext = context.applicationContext
    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val adjust: AdjustService?
    private val firebase: FirebaseService?
    private val facebook: FacebookService?
    private val billing: BillingService
    private val accounts: AccountRepository
    private val appManagement: AppManagementService

    private var nativeInternalTrackerEnabled: Boolean = false
    private var effectiveSandbox: Boolean = true
    private var noctuaAdjustAttribution: NoctuaAdjustAttribution? = null
    private var adjustAttribution: String = ""
    
    // Lifecycle callback
    private var lifecycleCallback: ((String) -> Unit)? = null

    // Billing callbacks
    private var billingPurchaseCallback: ((NoctuaPurchaseResult) -> Unit)? = null
    private var billingProductDetailsCallback: ((List<NoctuaProductDetails>) -> Unit)? = null
    private var billingQueryPurchasesCallback: ((List<NoctuaPurchaseResult>) -> Unit)? = null
    private var billingRestorePurchasesCallback: ((List<NoctuaPurchaseResult>) -> Unit)? = null
    private var billingProductPurchaseStatusCallback: ((NoctuaProductPurchaseStatus) -> Unit)? = null
    private var billingServerVerificationCallback: ((NoctuaPurchaseResult, ConsumableType) -> Unit)? = null

    init {
        AppContext.set(appContext)

        NoctuaLog.i(TAG, "Loading config from noctuagg.json")
        val config = loadConfig(appContext)

        if (config.clientId.isNullOrEmpty()) {
            throw IllegalArgumentException("clientId is not set")
        }

        // Host override (Unity) wins; otherwise fall back to bundled noctuagg.json.
        effectiveSandbox = resolveSandbox(sandboxEnabledOverride, config.noctua?.sandboxEnabled)
        NoctuaLog.sandboxEnabled = effectiveSandbox

        // The internal SDK's Koin is auto-initialized at process start by InternalNoctuaApp
        // (before Unity loads), and Unity never calls initApp()/initKoin() — so the internal
        // SDK can't receive the override at its own init. Push the host-resolved value into
        // its Koin-independent SandboxState now (this runs when Unity calls Noctua.init,
        // before the first internal event / network use) so its logging + is_sandbox event
        // field follow the override. Same SandboxState.setOverride that initKoin would call.
        NoctuaInternal.setSandboxEnabled(effectiveSandbox)
        NoctuaLog.d(TAG, "Config loaded: clientId=${config.clientId}, gameId=${config.gameId}")
        NoctuaLog.d(TAG, "Noctua config: sandboxEnabled=$effectiveSandbox (override=$sandboxEnabledOverride, config=${config.noctua?.sandboxEnabled}), nativeInternalTrackerEnabled=${config.noctua?.nativeInternalTrackerEnabled}")
        NoctuaLog.d(TAG, "Service configs: adjust=${config.adjust?.android != null}, firebase=${config.firebase?.android != null}, facebook=${config.facebook?.android != null}")

        nativeInternalTrackerEnabled =
            config.noctua?.nativeInternalTrackerEnabled ?: false

        NoctuaLog.i(TAG, "Creating AdjustService...")
        adjust = createAdjust(config)
        NoctuaLog.i(TAG, "AdjustService: ${if (adjust != null) "OK" else "SKIPPED (no config)"}")

        NoctuaLog.i(TAG, "Creating FirebaseService...")
        firebase = createFirebase(config)
        NoctuaLog.i(TAG, "FirebaseService: ${if (firebase != null) "OK" else "SKIPPED (no config)"}")

        NoctuaLog.i(TAG, "Creating FacebookService...")
        facebook = createFacebook(config)
        NoctuaLog.i(TAG, "FacebookService: ${if (facebook != null) "OK" else "SKIPPED"}")

        NoctuaLog.i(TAG, "Creating BillingService...")
        billing = createBilling()
        NoctuaLog.i(TAG, "BillingService: OK")

        accounts = AccountRepository(appContext)
        appManagement = AppManagementService(appContext)

        NoctuaLog.i(TAG, "AccountRepository initialized, starting sync...")
        coroutineScope.launch {
            accounts.syncOtherAccounts()
        }

        // Inspector (dev-only; gated on sandboxEnabled — zero work in prod).
        // Self-gates inside the bus/tailer as well, so safe even if Unity binds
        // a callback before this line.
        if (effectiveSandbox) {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.setEnabled(true)
            com.noctuagames.sdk.inspector.LogTailer.start()
            NoctuaLog.i(TAG, "Inspector bus enabled (sandboxEnabled=true); log tailer started")
        }

        NoctuaLog.i(TAG, "NoctuaPresenter initialized")
    }

    // ------------------------------------
    // Initialization
    // ------------------------------------

    fun initKoin() {
        // Pass the host-resolved sandbox flag so the internal SDK's logging + is_sandbox
        // event field follow the override instead of its own bundled noctuagg.json.
        initKoinManually(appContext, effectiveSandbox)
    }

    // ------------------------------------
    // Lifecycle
    // ------------------------------------

    fun onResume() {
        NoctuaLog.d(TAG, "onResume: adjust=${adjust != null}, nativeTracker=$nativeInternalTrackerEnabled, lifecycleCallback=${lifecycleCallback != null}")
        adjust?.onResume()

        if (nativeInternalTrackerEnabled) {
            NoctuaInternal.onInternalNoctuaApplicationPause(false)
        }

        coroutineScope.launch {
            accounts.syncOtherAccounts()
        }

        lifecycleCallback?.invoke("resume")
    }

    fun onPause() {
        NoctuaLog.d(TAG, "onPause: adjust=${adjust != null}, nativeTracker=$nativeInternalTrackerEnabled, lifecycleCallback=${lifecycleCallback != null}")
        adjust?.onPause()

        if (nativeInternalTrackerEnabled) {
            NoctuaInternal.onInternalNoctuaApplicationPause(true)
        }

        lifecycleCallback?.invoke("pause")
    }

    fun onDestroy() {
        NoctuaLog.d(TAG, "onDestroy: nativeTracker=$nativeInternalTrackerEnabled")
        if (nativeInternalTrackerEnabled) {
            NoctuaInternal.onInternalNoctuaDispose()
        }
    }

    fun onOnline() = adjust?.onOnline()
    fun onOffline() = adjust?.onOffline()

    fun registerLifecycleCallback(callback: ((String) -> Unit)?) {
        lifecycleCallback = callback
    }

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
            NoctuaLog.e(TAG, "Invalid ad revenue parameters")
            return
        }

        val payload = mapOf<String, Any?>(
            "source" to source,
            "revenue" to revenue,
            "currency" to currency,
            "extraPayload" to extraPayload
        )
        adjust?.let {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.emit("Adjust", "ad_revenue", payload, phase = com.noctuagames.sdk.inspector.NoctuaTrackerEventPhase.QUEUED)
            it.trackAdRevenue(source, revenue, currency, extraPayload)
        }
        firebase?.let {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.emit("Firebase", "ad_revenue", payload, phase = com.noctuagames.sdk.inspector.NoctuaTrackerEventPhase.QUEUED)
            com.noctuagames.sdk.inspector.LogTailer.registerPending("Firebase", "ad_revenue")
            it.trackAdRevenue(source, revenue, currency, extraPayload)
        }
        facebook?.let {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.emit("Facebook", "ad_revenue", payload, phase = com.noctuagames.sdk.inspector.NoctuaTrackerEventPhase.QUEUED)
            com.noctuagames.sdk.inspector.LogTailer.registerPending("Facebook", "ad_revenue")
            it.trackAdRevenue(source, revenue, currency, extraPayload)
        }
    }

    fun trackPurchase(
        orderId: String,
        amount: Double,
        currency: String,
        extraPayload: MutableMap<String, Any>
    ) {
        if (orderId.isEmpty() || amount <= 0 || currency.isEmpty()) {
            NoctuaLog.e(TAG, "Invalid purchase parameters")
            return
        }

        val payload = mapOf<String, Any?>(
            "orderId" to orderId,
            "amount" to amount,
            "currency" to currency,
            "extraPayload" to extraPayload
        )
        adjust?.let {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.emit("Adjust", "purchase", payload, phase = com.noctuagames.sdk.inspector.NoctuaTrackerEventPhase.QUEUED)
            it.trackPurchase(orderId, amount, currency, extraPayload)
        }
        firebase?.let {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.emit("Firebase", "purchase", payload, phase = com.noctuagames.sdk.inspector.NoctuaTrackerEventPhase.QUEUED)
            com.noctuagames.sdk.inspector.LogTailer.registerPending("Firebase", "purchase")
            it.trackPurchase(orderId, amount, currency, extraPayload)
        }
        facebook?.let {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.emit("Facebook", "purchase", payload, phase = com.noctuagames.sdk.inspector.NoctuaTrackerEventPhase.QUEUED)
            com.noctuagames.sdk.inspector.LogTailer.registerPending("Facebook", "purchase")
            it.trackPurchase(orderId, amount, currency, extraPayload)
        }
    }

    fun trackCustomEvent(
        eventName: String,
        payload: MutableMap<String, Any>
    ) {
        adjust?.let {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.emit("Adjust", eventName, payload, phase = com.noctuagames.sdk.inspector.NoctuaTrackerEventPhase.QUEUED)
            it.trackCustomEvent(eventName, payload)
        }
        firebase?.let {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.emit("Firebase", eventName, payload, phase = com.noctuagames.sdk.inspector.NoctuaTrackerEventPhase.QUEUED)
            com.noctuagames.sdk.inspector.LogTailer.registerPending("Firebase", eventName)
            it.trackCustomEvent(eventName, payload)
        }
        facebook?.let {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.emit("Facebook", eventName, payload, phase = com.noctuagames.sdk.inspector.NoctuaTrackerEventPhase.QUEUED)
            com.noctuagames.sdk.inspector.LogTailer.registerPending("Facebook", eventName)
            it.trackCustomEvent(eventName, payload)
        }

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
        val enriched: Map<String, Any?> = payload + mapOf("revenue" to revenue, "currency" to currency)
        adjust?.let {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.emit("Adjust", eventName, enriched, phase = com.noctuagames.sdk.inspector.NoctuaTrackerEventPhase.QUEUED)
            it.trackCustomEventWithRevenue(eventName, revenue, currency, payload)
        }
        firebase?.let {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.emit("Firebase", eventName, enriched, phase = com.noctuagames.sdk.inspector.NoctuaTrackerEventPhase.QUEUED)
            com.noctuagames.sdk.inspector.LogTailer.registerPending("Firebase", eventName)
            it.trackCustomEventWithRevenue(eventName, revenue, currency, payload)
        }
        facebook?.let {
            com.noctuagames.sdk.inspector.NoctuaInspectorBus.emit("Facebook", eventName, enriched, phase = com.noctuagames.sdk.inspector.NoctuaTrackerEventPhase.QUEUED)
            com.noctuagames.sdk.inspector.LogTailer.registerPending("Facebook", eventName)
            it.trackCustomEventWithRevenue(eventName, revenue, currency, payload)
        }
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

    fun getAdjustAdid(onResult: (String?) -> Unit) {
        adjust?.getAdjustAdid(onResult) ?: onResult(null)
    }

    fun getAdjustGoogleAdId(onResult: (String?) -> Unit) {
        adjust?.getAdjustGoogleAdId(onResult) ?: onResult(null)
    }

    fun getAdjustAmazonAdId(onResult: (String?) -> Unit) {
        adjust?.getAdjustAmazonAdId(onResult) ?: onResult(null)
    }

    fun getAdjustSdkVersion(onResult: (String?) -> Unit) {
        adjust?.getAdjustSdkVersion(onResult) ?: onResult(null)
    }

    // ------------------------------------
    // Notification Permission
    // ------------------------------------

    fun askNotificationPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            NoctuaLog.d(TAG, "Notification permission auto-granted (< Android 13)")
            return
        }

        val permission = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.POST_NOTIFICATIONS
        )

        if (permission == PackageManager.PERMISSION_GRANTED) {
            NoctuaLog.d(TAG, "Notification permission already granted")
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
                NoctuaLog.e(TAG, "Billing error: $error - $message")
                onBillingError?.invoke(error, message)
            }
        })
    }

    /**
     * Initializes billing with a typed [BillingEventListener] interface.
     *
     * Prefer this overload when calling from Unity/JNI to avoid Kotlin Function1 type erasure
     * which causes custom object parameters to appear as java.lang.Object.
     */
    fun initializeBilling(listener: BillingEventListener) {
        billing.initialize(listener)
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
    // In-App Review & Updates
    // ------------------------------------

    fun requestInAppReview(activity: Activity, onResult: (Boolean) -> Unit) =
        appManagement.requestInAppReview(activity, onResult)

    fun checkForUpdate(onResult: (String) -> Unit) =
        appManagement.checkForUpdate(onResult)

    fun startImmediateUpdate(activity: Activity, onResult: (Int) -> Unit) =
        appManagement.startImmediateUpdate(activity, onResult)

    fun startFlexibleUpdate(activity: Activity, onProgress: (Float) -> Unit, onResult: (Int) -> Unit) =
        appManagement.startFlexibleUpdate(activity, onProgress, onResult)

    fun completeUpdate() =
        appManagement.completeUpdate()

    // ------------------------------------
    // Private SDK Initialization
    // ------------------------------------

    private fun createBilling(): BillingService {
        return BillingService(appContext, billingConfig)
    }

    private fun createAdjust(config: NoctuaConfig): AdjustService? =
        try {
            config.adjust?.android?.let {
                AdjustService(it, appContext, effectiveSandbox) { attribution ->
                    noctuaAdjustAttribution = attribution
                    adjustAttribution = attribution.toJsonString()
                }
            }
        } catch (e: Exception) {
            NoctuaLog.w(TAG, "Adjust init failed: ${e.message}")
            null
        }

    private fun createFirebase(config: NoctuaConfig): FirebaseService? =
        try {
            config.firebase?.android?.let {
                FirebaseService(it, appContext)
            }
        } catch (e: Exception) {
            NoctuaLog.w(TAG, "Firebase init failed: ${e.message}")
            null
        }

    private fun createFacebook(config: NoctuaConfig): FacebookService? =
        try {
            config.facebook?.android?.let {
                FacebookService(it, appContext, effectiveSandbox)
            }
        } catch (e: Exception) {
            NoctuaLog.w(TAG, "Facebook init failed: ${e.message}")
            null
        }

    companion object {
        /**
         * Resolves the effective sandbox flag: a host-supplied [override] wins; otherwise the
         * bundled `noctuagg.json` value ([configValue]); otherwise `true` (sandbox-on default).
         */
        @JvmStatic
        fun resolveSandbox(override: Boolean?, configValue: Boolean?): Boolean =
            override ?: (configValue ?: true)
    }
}
