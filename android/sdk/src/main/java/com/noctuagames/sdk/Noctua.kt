package com.noctuagames.sdk

import android.app.Activity
import android.content.Context
import android.util.Log
import com.noctuagames.sdk.models.Account
import com.noctuagames.sdk.models.BillingErrorCode
import com.noctuagames.sdk.models.ConsumableType
import com.noctuagames.sdk.models.NoctuaBillingConfig
import com.noctuagames.sdk.models.NoctuaProductDetails
import com.noctuagames.sdk.models.ProductType
import com.noctuagames.sdk.models.NoctuaProductPurchaseStatus
import com.noctuagames.sdk.models.NoctuaPurchaseResult
import com.noctuagames.sdk.presenter.NoctuaPresenter

/**
 * Public API entry point for the Noctua Native SDK.
 *
 * This object exposes a stable surface for Unity and host applications.
 * All business logic is delegated to [NoctuaPresenter].
 *
 */
object Noctua {

    private const val TAG = "NoctuaAPI"
    private lateinit var presenter: NoctuaPresenter

    // ------------------------------------
    // Initialization
    // ------------------------------------

    /**
     * Initializes internal dependency injection (Koin).
     *
     * Must be called before [init].
     */
    fun initApp() {
        presenter.initKoin()
    }

    /**
     * Initializes the Noctua SDK.
     *
     * @param context Application or Activity context.
     * @param publishedApps Optional list of published application identifiers.
     * @param billingConfig Optional billing configuration. If not provided, defaults are used.
     */
    fun init(
        context: Context,
        publishedApps: List<String> = emptyList(),
        billingConfig: NoctuaBillingConfig = NoctuaBillingConfig()
    ) {
        presenter = NoctuaPresenter(context, publishedApps, billingConfig)
        askNotificationPermission(context as Activity)
    }

    // ------------------------------------
    // Lifecycle
    // ------------------------------------

    /** Should be called from the host application's onResume(). */
    fun onResume() = ensureInit { presenter.onResume() }

    /** Should be called from the host application's onPause(). */
    fun onPause() = ensureInit { presenter.onPause() }

    /** Should be called from the host application's onDestroy(). */
    fun onDestroy() = ensureInit { presenter.onDestroy() }

    /** Notifies SDK that device is online. */
    fun onOnline() = ensureInit { presenter.onOnline() }

    /** Notifies SDK that device is offline. */
    fun onOffline() = ensureInit { presenter.onOffline() }

    // ------------------------------------
    // Tracking
    // ------------------------------------

    /**
     * Tracks ad revenue event.
     *
     * @param source Mediation or network source.
     * @param revenue Revenue amount.
     * @param currency ISO currency code (e.g., USD).
     * @param extraPayload Optional additional parameters.
     */
    fun trackAdRevenue(
        source: String,
        revenue: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) = ensureInit {
        presenter.trackAdRevenue(source, revenue, currency, extraPayload)
    }

    /**
     * Tracks in-app purchase event.
     *
     * @param orderId Unique purchase identifier.
     * @param amount Purchase amount.
     * @param currency ISO currency code.
     * @param extraPayload Optional additional parameters.
     */
    fun trackPurchase(
        orderId: String,
        amount: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) = ensureInit {
        presenter.trackPurchase(orderId, amount, currency, extraPayload)
    }

    /**
     * Tracks a custom analytics event.
     *
     * @param eventName Event name.
     * @param payload Optional event parameters.
     */
    fun trackCustomEvent(
        eventName: String,
        payload: MutableMap<String, Any> = mutableMapOf()
    ) = ensureInit {
        presenter.trackCustomEvent(eventName, payload)
    }

    /**
     * Tracks a custom event with revenue value.
     * @param eventName Event name.
     * @param revenue Revenue amount.
     * @param currency ISO currency code.
     * @param payload Optional event parameters.
     */
    fun trackCustomEventWithRevenue(
        eventName: String,
        revenue: Double,
        currency: String,
        payload: MutableMap<String, Any> = mutableMapOf()
    ) = ensureInit {
        presenter.trackCustomEventWithRevenue(eventName, revenue, currency, payload)
    }

    // ------------------------------------
    // Accounts
    // ------------------------------------

    /** Returns all stored accounts. */
    fun getAccounts(): List<Account> =
        ifInitialized { presenter.getAccounts() } ?: emptyList()

    /**
     * Returns a specific account.
     *
     * @param userId User identifier.
     * @param gameId Game identifier.
     */
    fun getAccount(userId: Long, gameId: Long): Account? =
        ifInitialized { presenter.getAccount(userId, gameId) }

    /** Returns accounts filtered by user ID. */
    fun getAccountsByUserId(userId: Long): List<Account> =
        ifInitialized { presenter.getAccountsByUserId(userId) } ?: emptyList()

    /** Saves or updates an account. */
    fun putAccount(account: Account) =
        ensureInit { presenter.putAccount(account) }

    /** Deletes an account. */
    fun deleteAccount(account: Account): Int =
        ifInitialized { presenter.deleteAccount(account) } ?: 0

    // ------------------------------------
    // Firebase IDs
    // ------------------------------------

    /** Retrieves Firebase Installation ID. */
    fun getFirebaseInstallationID(onResult: (String) -> Unit) =
        ensureInit { presenter.getFirebaseInstallationID(onResult) }

    /** Retrieves Firebase Analytics Session ID. */
    fun getFirebaseAnalyticsSessionID(onResult: (String) -> Unit) =
        ensureInit { presenter.getFirebaseAnalyticsSessionID(onResult) }

    // ------------------------------------
    // Remote Config
    // ------------------------------------

    /** Returns Firebase Remote Config string value. */
    fun getFirebaseRemoteConfigString(key: String, onResult: (String) -> Unit) =
        ensureInit {
            onResult(presenter.getFirebaseRemoteConfigString(key) ?: "")
        }

    /** Returns Firebase Remote Config boolean value. */
    fun getFirebaseRemoteConfigBoolean(key: String, onResult: (Boolean) -> Unit) =
        ensureInit {
            onResult(presenter.getFirebaseRemoteConfigBoolean(key) ?: false)
        }

    /** Returns Firebase Remote Config double value. */
    fun getFirebaseRemoteConfigDouble(key: String, onResult: (Double) -> Unit) =
        ensureInit {
            onResult(presenter.getFirebaseRemoteConfigDouble(key) ?: 0.0)
        }

    /** Returns Firebase Remote Config long value. */
    fun getFirebaseRemoteConfigLong(key: String, onResult: (Long) -> Unit) =
        ensureInit {
            onResult(presenter.getFirebaseRemoteConfigLong(key) ?: 0L)
        }

    // ------------------------------------
    // Attribution
    // ------------------------------------

    /** Returns Adjust attribution data as JSON string. */
    fun getAdjustAttribution(onResult: (String) -> Unit) =
        ensureInit { presenter.getAdjustAttribution(onResult) }

    // ------------------------------------
    // Notification Permission
    // ------------------------------------

    /**
     * Requests Android 13+ notification permission if required.
     */
    private fun askNotificationPermission(activity: Activity) =
        ensureInit { presenter.askNotificationPermission(activity) }

    // ------------------------------------
    // Internal Tracker Configuration
    // ------------------------------------

    /**
     * Sets additional session parameters.
     *
     * These parameters will be attached to subsequent analytics events.
     *
     * @param extraParams Key-value map containing additional session metadata.
     */
    fun setSessionExtraParams(extraParams: Map<String, Any>) =
        ensureInit { presenter.setSessionExtraParams(extraParams) }

    /**
     * Sets a session tag used for segmentation or internal tracking.
     *
     * @param tag Custom session identifier.
     */
    fun setSessionTag(tag: String) =
        ensureInit { presenter.setSessionTag(tag) }

    /**
     * Returns the currently active session tag.
     *
     * @return Session tag or empty string if SDK is not initialized.
     */
    fun getSessionTag(): String =
        ifInitialized { presenter.getSessionTag() } ?: ""

    /**
     * Sets experiment identifier for A/B testing purposes.
     *
     * @param experiment Experiment name or variant identifier.
     */
    fun setExperiment(experiment: String) =
        ensureInit { presenter.setExperiment(experiment) }

    /**
     * Returns the active experiment identifier.
     *
     * @return Experiment name or empty string if not initialized.
     */
    fun getExperiment(): String =
        ifInitialized { presenter.getExperiment() } ?: ""

    /**
     * Sets a general experiment value.
     *
     * This allows storing multiple experiment values internally.
     *
     * @param experiment Experiment value.
     */
    fun setGeneralExperiment(experiment: String) =
        ensureInit { presenter.setGeneralExperiment(experiment) }

    /**
     * Returns a general experiment value by key.
     *
     * @param experimentKey Key of the experiment.
     * @return Experiment value or empty string if not found or not initialized.
     */
    fun getGeneralExperiment(experimentKey: String): String =
        ifInitialized { presenter.getGeneralExperiment(experimentKey) } ?: ""

    // ------------------------------------
    // Events Local Storage
    // ------------------------------------

    /**
     * Saves externally generated events into SDK local storage.
     *
     * @param jsonString JSON string containing event data.
     */
    fun saveEvents(jsonString: String) =
        ensureInit { presenter.saveEvents(jsonString) }

    /**
     * Retrieves locally stored events.
     *
     * @param onResult Callback returning list of JSON event strings.
     */
    fun getEvents(onResult: (List<String>) -> Unit) =
        ensureInit { presenter.getEvents(onResult) }

    /**
     * Deletes all locally stored events.
     */
    fun deleteEvents() =
        ensureInit { presenter.deleteEvents() }

    // ------------------------------------
    // Events Per-Row Storage (Unlimited)
    // ------------------------------------

    /**
     * Inserts a single event JSON into per-row database storage.
     *
     * @param eventJson Serialized JSON string for one event.
     */
    fun insertEvent(eventJson: String) =
        ensureInit { presenter.insertEvent(eventJson) }

    /**
     * Retrieves a batch of events from database storage.
     *
     * @param limit Maximum number of events to return.
     * @param offset Number of events to skip.
     * @param onResult Callback returning JSON array of event objects.
     */
    fun getEventsBatch(limit: Int, offset: Int, onResult: (String) -> Unit) =
        ensureInit { presenter.getEventsBatch(limit, offset, onResult) }

    /**
     * Deletes specific events by their database IDs.
     *
     * @param idsJson JSON array string of IDs to delete, e.g. "[1,2,3]".
     * @param onResult Callback returning the number of deleted rows.
     */
    fun deleteEventsByIds(idsJson: String, onResult: (Int) -> Unit) =
        ensureInit { presenter.deleteEventsByIds(idsJson, onResult) }

    /**
     * Returns the total count of stored events.
     *
     * @param onResult Callback returning the event count.
     */
    fun getEventCount(onResult: (Int) -> Unit) =
        ensureInit { presenter.getEventCount(onResult) }

    // ------------------------------------
    // In-App Purchases (Billing)
    // ------------------------------------

    /**
     * Initializes the billing service for in-app purchases.
     *
     * @param onPurchaseCompleted Callback when a purchase is completed.
     * @param onPurchaseUpdated Callback when a purchase is updated.
     * @param onProductDetailsLoaded Callback when product details are loaded.
     * @param onQueryPurchasesCompleted Callback when purchases are queried.
     * @param onRestorePurchasesCompleted Callback when restore purchases completes.
     * @param onProductPurchaseStatusResult Callback with the purchase status of a product.
     * @param onServerVerificationRequired Callback when a purchase requires server verification.
     *   The integrator must verify the purchase on their server and then call
     *   [completePurchaseProcessing] with the result.
     * @param onBillingError Callback when a billing error occurs.
     */
    fun initializeBilling(
        onPurchaseCompleted: ((NoctuaPurchaseResult) -> Unit)? = null,
        onPurchaseUpdated: ((NoctuaPurchaseResult) -> Unit)? = null,
        onProductDetailsLoaded: ((List<NoctuaProductDetails>) -> Unit)? = null,
        onQueryPurchasesCompleted: ((List<NoctuaPurchaseResult>) -> Unit)? = null,
        onRestorePurchasesCompleted: ((List<NoctuaPurchaseResult>) -> Unit)? = null,
        onProductPurchaseStatusResult: ((NoctuaProductPurchaseStatus) -> Unit)? = null,
        onServerVerificationRequired: ((NoctuaPurchaseResult, ConsumableType) -> Unit)? = null,
        onBillingError: ((BillingErrorCode, String) -> Unit)? = null
    ) = ensureInit {
        presenter.initializeBilling(onPurchaseCompleted, onPurchaseUpdated, onProductDetailsLoaded, onQueryPurchasesCompleted, onRestorePurchasesCompleted, onProductPurchaseStatusResult, onServerVerificationRequired, onBillingError)
    }

    /**
     * Registers a product with its consumable type.
     *
     * @param productId The product ID from Google Play Console.
     * @param consumableType The type of product (CONSUMABLE, NON_CONSUMABLE, SUBSCRIPTION).
     */
    fun registerProduct(productId: String, consumableType: ConsumableType) =
        ensureInit { presenter.registerProduct(productId, consumableType) }

    /**
     * Queries product details from Google Play.
     *
     * @param productIds List of product IDs to query.
     * @param productType Type of products (INAPP or SUBS).
     */
    fun queryProductDetails(productIds: List<String>, productType: ProductType = ProductType.INAPP) =
        ensureInit { presenter.queryProductDetails(productIds, productType) }

    /**
     * Launches the billing flow for a purchase.
     *
     * @param activity The activity to launch the billing flow from.
     * @param productDetails The product details to purchase.
     */
    fun launchBillingFlow(activity: Activity, productDetails: NoctuaProductDetails) =
        ensureInit { presenter.launchBillingFlow(activity, productDetails) }

    /**
     * Queries existing purchases.
     *
     * @param productType Type of products to query.
     */
    fun queryPurchases(productType: ProductType = ProductType.INAPP) =
        ensureInit { presenter.queryPurchases(productType) }

    /**
     * Acknowledges a purchase.
     *
     * @param purchaseToken The purchase token to acknowledge.
     * @param callback Callback with success status.
     */
    fun acknowledgePurchase(purchaseToken: String, callback: ((Boolean) -> Unit)? = null) =
        ensureInit { presenter.acknowledgePurchase(purchaseToken, callback) }

    /**
     * Consumes a purchase (for consumable products).
     *
     * @param purchaseToken The purchase token to consume.
     * @param callback Callback with success status.
     */
    fun consumePurchase(purchaseToken: String, callback: ((Boolean) -> Unit)? = null) =
        ensureInit { presenter.consumePurchase(purchaseToken, callback) }

    /**
     * Completes purchase processing after server verification.
     *
     * Call this after your server has verified (and acknowledged) the purchase
     * received via [onServerVerificationRequired].
     * - For **consumables**: consumes the purchase client-side so it can be bought again.
     * - For **non-consumables / subscriptions**: no client-side action needed since
     *   the server already acknowledged via the Google Play Developer API.
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
    ) = ensureInit {
        presenter.completePurchaseProcessing(purchaseToken, consumableType, verified, callback)
    }

    /**
     * Restores all purchases by querying both INAPP and SUBS purchases.
     * Unacknowledged purchases are automatically processed (acknowledged or consumed)
     * based on their registered consumable type.
     */
    fun restorePurchases() =
        ensureInit { presenter.restorePurchases() }

    /**
     * Gets the purchase status of a specific product.
     * The result is returned via the [onProductPurchaseStatusResult] callback
     * registered in [initializeBilling].
     *
     * @param productId The product ID to check.
     */
    fun getProductPurchaseStatus(productId: String) =
        ensureInit { presenter.getProductPurchaseStatus(productId) }

    /**
     * Reconnects the billing client.
     */
    fun reconnectBilling() =
        ensureInit { presenter.reconnectBilling() }

    /**
     * Disposes the billing service.
     */
    fun disposeBilling() =
        ensureInit { presenter.disposeBilling() }

    /**
     * Checks if billing client is ready.
     *
     * @return True if billing is ready, false otherwise.
     */
    fun isBillingReady(): Boolean =
        ifInitialized { presenter.isBillingReady() } ?: false

    // ------------------------------------
    // Internal Helpers
    // ------------------------------------

    /**
     * Ensures SDK is initialized before executing logic.
     */
    private fun ensureInit(block: () -> Unit) {
        if (!::presenter.isInitialized) {
            Log.e(TAG, "Noctua is not initialized. Call init() first.")
            return
        }
        block()
    }

    /**
     * Executes block only if SDK is initialized.
     */
    private fun <T> ifInitialized(block: () -> T): T? {
        if (!::presenter.isInitialized) {
            Log.e(TAG, "Noctua is not initialized. Call init() first.")
            return null
        }
        return block()
    }
}
