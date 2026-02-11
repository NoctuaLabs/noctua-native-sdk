package com.noctuagames.sdk

import android.app.Activity
import android.content.Context
import android.util.Log
import com.noctuagames.sdk.models.Account
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
     */
    fun init(context: Context, publishedApps: List<String> = emptyList()) {
        presenter = NoctuaPresenter(context, publishedApps)
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
