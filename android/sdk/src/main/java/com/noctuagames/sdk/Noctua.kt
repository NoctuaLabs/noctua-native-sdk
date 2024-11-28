package com.noctuagames.sdk

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.util.Log
import com.google.gson.GsonBuilder
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.io.IOException

data class NoctuaConfig(
    val clientId: String?,
    val adjust: AdjustServiceConfig?,
    val firebase: FirebaseServiceConfig?,
    val facebook: FacebookServiceConfig?,
)

class Noctua(context: Context, publishedApps: List<String>) {
    private val clientId: String
    private val adjust: AdjustService?
    private val firebase: FirebaseService?
    private val facebook: FacebookService?
    private val accounts: AccountRepository
    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    init {
        val config = loadAppConfig(context)

        if (config.clientId.isNullOrEmpty()) {
            throw IllegalArgumentException("clientId is not set")
        }

        this.clientId = config.clientId

        val adjustAvailable =
            try {
                Class.forName("com.adjust.sdk.Adjust")
                true
            } catch (e: ClassNotFoundException) {
                false
            }

        if (!adjustAvailable) {
            Log.w(TAG, "Adjust SDK is not found.")
            adjust = null
        } else if (config.adjust == null) {
            Log.w(TAG, "Adjust configuration is not found.")
            adjust = null
        } else {
            adjust = try {
                AdjustService(config.adjust, context)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to initialize Adjust SDK: ${e.message}")
                null
            }
        }

        if (adjust == null) {
            Log.w(TAG, "Adjust tracking is disabled.")
        }

        val firebaseAvailable =
            try {
                Class.forName("com.google.firebase.FirebaseApp")
                true
            } catch (_: ClassNotFoundException) {
                false
            }

        if (!firebaseAvailable) {
            Log.w(TAG, "Firebase SDK is not found.")
            firebase = null
        } else if (config.firebase == null) {
            Log.w(TAG, "Firebase configuration is not found.")
            firebase = null
        } else {
            firebase = try {
                FirebaseService(config.firebase, context)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to initialize Firebase SDK: ${e.message}")
                null
            }
        }

        if (firebase == null) {
            Log.w(TAG, "Firebase tracking is disabled.")
        }

        val facebookAvailable =
            try {
                Class.forName("com.facebook.appevents.AppEventsLogger")
                true
            } catch (_: ClassNotFoundException) {
                Log.w(TAG, "Firebase SDK is not found.")
                false
            }

        if (!facebookAvailable) {
            Log.w(TAG, "Facebook SDK is not found.")
            facebook = null
        } else if (config.facebook == null) {
            Log.w(TAG, "Facebook configuration is not found.")
            facebook = null
        } else {
            facebook = try {
                FacebookService(config.facebook, context)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to initialize Facebook SDK: ${e.message}")
                null
            }
        }

        if (facebook == null) {
            Log.w(TAG, "Facebook tracking is disabled.")
        }

        accounts = AccountRepository(context, publishedApps)

        coroutineScope.launch {
            accounts.syncOtherAccounts()
        }

        Log.i(TAG, "Noctua initialized")
    }

    fun onResume() {
        adjust?.onResume()

        coroutineScope.launch {
            accounts.syncOtherAccounts()
        }
    }

    fun onPause() {
        adjust?.onPause()
    }

    fun trackAdRevenue(
        source: String,
        revenue: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        if (source.isEmpty()) {
            Log.e(TAG, "source is empty")
            return
        }

        if (revenue <= 0) {
            Log.e(TAG, "revenue is negative or zero")
            return
        }

        if (currency.isEmpty()) {
            Log.e(TAG, "currency is empty")
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
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        if (orderId.isEmpty()) {
            Log.e(TAG, "orderId is empty")
            return
        }

        if (amount <= 0) {
            Log.e(TAG, "amount is negative or zero")
            return
        }

        if (currency.isEmpty()) {
            Log.e(TAG, "currency is empty")
            return
        }

        adjust?.trackPurchase(orderId, amount, currency, extraPayload)
        firebase?.trackPurchase(orderId, amount, currency, extraPayload)
        facebook?.trackPurchase(orderId, amount, currency, extraPayload)
    }

    fun trackCustomEvent(eventName: String, payload: MutableMap<String, Any> = mutableMapOf()) {
        adjust?.trackCustomEvent(eventName, payload)
        firebase?.trackCustomEvent(eventName, payload)
        facebook?.trackCustomEvent(eventName, payload)
    }

    companion object {
        private val TAG = this::class.simpleName
        private lateinit var instance: Noctua

        fun init(context: Context, publishedApps: List<String>) {
            Log.w(TAG, "init")

            instance = Noctua(context, publishedApps)
        }

        fun onResume() {
            if (!::instance.isInitialized) {
                Log.e(TAG, "Noctua is not initialized. Call init() first.")
                return
            }

            instance.onResume()
        }

        fun onPause() {
            if (!::instance.isInitialized) {
                Log.e(TAG, "Noctua is not initialized. Call init() first.")
                return
            }

            instance.onPause()
        }

        fun trackAdRevenue(
            source: String,
            revenue: Double,
            currency: String,
            extraPayload: MutableMap<String, Any> = mutableMapOf()
        ) {
            if (!::instance.isInitialized) {
                Log.e(TAG, "Noctua is not initialized. Call init() first.")
                return
            }

            instance.trackAdRevenue(source, revenue, currency, extraPayload)
        }

        fun trackPurchase(
            orderId: String,
            amount: Double,
            currency: String,
            extraPayload: MutableMap<String, Any> = mutableMapOf()
        ) {
            if (!::instance.isInitialized) {
                Log.e(TAG, "Noctua is not initialized. Call init() first.")
                return
            }

            instance.trackPurchase(orderId, amount, currency, extraPayload)
        }

        fun trackCustomEvent(eventName: String, payload: MutableMap<String, Any> = mutableMapOf()) {
            if (!::instance.isInitialized) {
                Log.e(TAG, "Noctua is not initialized. Call init() first.")
                return
            }

            instance.trackCustomEvent(eventName, payload)
        }

        fun getAccounts(): List<Account> {
            return instance.accounts.getAll()
        }

        fun getAccount(userId: Long, gameId: Long): Account? {
            return instance.accounts.getSingle(userId, gameId)
        }

        fun getAccountsByUserId(userId: Long): List<Account> {
            return instance.accounts.getByUserId(userId)
        }

        fun putAccount(account: Account) {
            instance.accounts.put(account)
        }

        fun deleteAccount(account: Account): Int {
            return instance.accounts.delete(account.userId, account.gameId)
        }
    }
}

fun loadAppConfig(context: Context): NoctuaConfig {
    try {
        context.assets.open("noctuagg.json").use {
            val buffer = ByteArray(it.available())
            it.read(buffer)
            val json = String(buffer)

            // Create a Gson instance with custom field naming policy
            val gson = GsonBuilder().create()

            return gson.fromJson(json, NoctuaConfig::class.java)
        }
    } catch (e: IOException) {
        throw IllegalArgumentException("Failed to load noctuagg.json", e)
    }
}