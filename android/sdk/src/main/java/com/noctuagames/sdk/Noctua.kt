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
                Log.w(TAG, "Adjust SDK is not found. Adjust tracking will be disabled.")
                false
            }

        if (adjustAvailable && config.adjust != null) {
            adjust = AdjustService(config.adjust)
            adjust?.onCreate(context)
        }

        val firebaseAvailable =
            try {
                Class.forName("com.google.firebase.FirebaseApp")
                true
            } catch (e: ClassNotFoundException) {
                Log.w(TAG, "Firebase SDK is not found. Firebase tracking will be disabled.")
                false
            }

        if (firebaseAvailable && config.firebase != null) {
            firebase = FirebaseService(config.firebase);
            firebase?.onCreate(context)

        }

        val facebookAvailable =
            try {
                Class.forName("com.facebook.FacebookSdk")
                true
            } catch (e: ClassNotFoundException) {
                Log.w(TAG, "Firebase SDK is not found. Facebook tracking will be disabled.")
                false
            }

        if (facebookAvailable && config.facebook != null) {
            facebook = FacebookService(config.facebook);
            facebook?.onCreate(context)

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
        firebase?.onResume()
        facebook?.onResume()
    }

    fun onPause() {
        checkInit();
        adjust?.onPause()
        firebase?.onResume()
        facebook?.onResume()
    }

    fun trackCustomEvent(eventName: String, payload: MutableMap<String, Any> = mutableMapOf()) {
        checkInit()
        adjust?.trackCustomEvent(eventName, payload)
        firebase?.trackCustomEvent(eventName, payload)
        facebook?.trackCustomEvent(eventName, payload)
        noctua?.trackCustomEvent(eventName, payload)
    }

    fun trackAdRevenue(
        source: String,
        revenue: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        checkInit();
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

        adjust?.trackPurchase(orderId, amount, currency, extraPayload)
        firebase?.trackPurchase(orderId, amount, currency, extraPayload)
        facebook?.trackPurchase(orderId, amount, currency, extraPayload)
        noctua?.trackPurchase(orderId, amount, currency, extraPayload)
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
