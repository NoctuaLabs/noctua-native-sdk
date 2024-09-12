package com.noctuagames.sdk

import android.content.Context
import android.util.Log
import com.google.gson.GsonBuilder
import com.google.gson.FieldNamingPolicy
import java.io.IOException

data class NoctuaConfig(
    val clientId: String?,
    val adjust: AdjustServiceConfig?,
    val firebase: FirebaseServiceConfig?,
    val facebook: FacebookServiceConfig?,
    val noctua: NoctuaServiceConfig?,
)

class Noctua {
    private lateinit var clientId: String
    private var adjust: AdjustService? = null
    private var firebase: FirebaseService? = null
    private var facebook: FacebookService? = null
    private var noctua: NoctuaService? = null

    fun init(context: Context) {
        Log.w(TAG, "init")
        val config = loadAppConfig(context)

        if (config.clientId.isNullOrEmpty()) {
            throw IllegalArgumentException("clientId is not set in noctuagg.json")
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
        }
        else if (config.adjust == null) {
            Log.w(TAG, "Adjust configuration is not found.")
        }
        else {
            try {
                adjust = AdjustService(config.adjust, context)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to initialize Adjust SDK: ${e.message}")
            }
        }

        if (adjust == null) {
            Log.w(TAG, "Adjust tracking is disabled.")
        }

        val firebaseAvailable =
            try {
                Class.forName("com.google.firebase.FirebaseApp")
                true
            } catch (e: ClassNotFoundException) {
                false
            }

        if (!firebaseAvailable) {
            Log.w(TAG, "Firebase SDK is not found.")
        }
        else if (config.firebase == null) {
            Log.w(TAG, "Firebase configuration is not found.")
        }
        else {
            try {
                firebase = FirebaseService(config.firebase, context)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to initialize Firebase SDK: ${e.message}")
            }
        }

        if (firebase == null) {
            Log.w(TAG, "Firebase tracking is disabled.")
        }

        val facebookAvailable =
            try {
                Class.forName("com.facebook.FacebookSdk")
                true
            } catch (e: ClassNotFoundException) {
                Log.w(TAG, "Firebase SDK is not found.")
                false
            }

        if (!facebookAvailable) {
            Log.w(TAG, "Facebook SDK is not found.")
        }
        else if (config.facebook == null) {
            Log.w(TAG, "Facebook configuration is not found.")
        }
        else {
            try {
                facebook = FacebookService(config.facebook, context)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to initialize Facebook SDK: ${e.message}")
            }
        }

        if (facebook == null) {
            Log.w(TAG, "Facebook tracking is disabled.")
        }

        noctua = config.noctua?.let {
            NoctuaService(it, context, adjust != null)
        }

        noctua?.trackFirstInstall()
    }

    private fun checkInit() {
        if (!this::clientId.isInitialized) {
            throw IllegalArgumentException("SDK not initialized. Call init() first.")
        }
    }

    fun onResume() {
        checkInit();
        adjust?.onResume()
    }

    fun onPause() {
        checkInit();
        adjust?.onPause()
    }

    fun trackAdRevenue(
        source: String,
        revenue: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        checkInit();

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
        noctua?.trackAdRevenue(source, revenue, currency, extraPayload)
    }

    fun trackPurchase(
        orderId: String,
        amount: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        checkInit();

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
        noctua?.trackPurchase(orderId, amount, currency, extraPayload)
    }

    fun trackCustomEvent(eventName: String, payload: MutableMap<String, Any> = mutableMapOf()) {
        checkInit()
        adjust?.trackCustomEvent(eventName, payload)
        firebase?.trackCustomEvent(eventName, payload)
        facebook?.trackCustomEvent(eventName, payload)
        noctua?.trackCustomEvent(eventName, payload)
    }

    companion object {
        private val TAG = Noctua::class.simpleName
        private val instance = Noctua()

        fun init(context: Context) {
            Log.w(TAG, "init")
            instance.init(context)
        }

        fun onResume() {
            instance.onResume()
        }

        fun onPause() {
            instance.onPause()
        }

        fun trackAdRevenue(
            source: String,
            revenue: Double,
            currency: String,
            extraPayload: MutableMap<String, Any> = mutableMapOf()
        ) {
            instance.trackAdRevenue(source, revenue, currency, extraPayload)
        }

        fun trackPurchase(
            orderId: String,
            amount: Double,
            currency: String,
            extraPayload: MutableMap<String, Any> = mutableMapOf()
        ) {
            instance.trackPurchase(orderId, amount, currency, extraPayload)
        }

        fun trackCustomEvent(eventName: String, payload: MutableMap<String, Any> = mutableMapOf()) {
            instance.trackCustomEvent(eventName, payload)
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
            val gson = GsonBuilder()
                .create()

            return gson.fromJson(json, NoctuaConfig::class.java)
        }
    } catch (e: IOException) {
        throw IllegalArgumentException("Failed to load noctuagg.json", e)
    }
}
