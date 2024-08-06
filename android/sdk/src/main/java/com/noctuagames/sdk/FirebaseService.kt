package com.noctuagames.sdk

import android.content.Context
import android.util.Log
import android.os.Bundle
import com.adjust.sdk.AdjustAdRevenue

import com.google.firebase.analytics.FirebaseAnalytics

data class FirebaseServiceConfig(
    // Credentials are written in Android Resources
    val eventMap: Map<String, String>,
)


class FirebaseService(private val config: FirebaseServiceConfig) {
    companion object {
        private lateinit var firebaseContext: Context
        private val TAG = FirebaseService::class.simpleName
    }
    private lateinit var Analytics: FirebaseAnalytics

    init {
        if (config.eventMap.isEmpty()) {
            throw IllegalArgumentException("Event map for Firebase is not set in noctuaggconfig.json")
        }
        if (!config.eventMap.containsKey("AdRevenue")) {
            throw IllegalArgumentException("Event name for Firebase Purchase is not set in noctuaggconfig.json")
        }
        if (!config.eventMap.containsKey("Purchase")) {
            throw IllegalArgumentException("Event name for Firebase Purchase is not set in noctuaggconfig.json")
        }
    }

    fun onCreate(context: Context) {
        firebaseContext = context
        Log.w(TAG, "NoctuaFirebase.onCreate")
        Log.w(TAG, "Noctua's Firebase initialization")
        try {
            Log.w(TAG, "Firebase initialized successfully")
            Analytics = FirebaseAnalytics.getInstance(firebaseContext)
            Log.w(TAG, "Firebase Analytics initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing Firebase: ${e.message}", e)
        }

    }

    fun onResume() {
    }

    fun onPause() {
    }

    fun trackAdRevenue(
        source: String,
        revenue: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        val bundle = Bundle().apply {
            putString("source", source)
            putDouble("ad_revenue", revenue)
            putString("currency", currency)
        }
        for ((key, value) in extraPayload) {
            when (value) {
                is Int -> bundle.putInt(key, value)
                else -> bundle.putString(key, value.toString())
            }
        }
        Analytics.logEvent("AdRevenue", bundle)
        Log.w(TAG, "Ad revenue event logged: Source: $source, Revenue: $revenue, Currency: $currency")
    }

    fun trackPurchase(
        orderId: String,
        amount: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        if (orderId.isEmpty()) {
            throw IllegalArgumentException("orderId is not set")
        }

        if (amount <= 0) {
            throw IllegalArgumentException("revenue is negative or zero")
        }

        if (currency.isEmpty()) {
            throw IllegalArgumentException("currency is not set")
        }

        val bundle = Bundle().apply {
            putString(FirebaseAnalytics.Param.CURRENCY, currency)
            putDouble(FirebaseAnalytics.Param.VALUE, amount)
            putString(FirebaseAnalytics.Param.TRANSACTION_ID, orderId)

        }
        for ((key, value) in extraPayload) {
            when (value) {
                is Int -> bundle.putInt(key, value)
                else -> bundle.putString(key, value.toString())
            }
        }
        Analytics.logEvent(FirebaseAnalytics.Event.PURCHASE, bundle)
        Log.w(TAG, "Purchase event logged: $currency, $amount, $orderId, $extraPayload")
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        if (!config.eventMap.containsKey(eventName)) {
            Log.w(FirebaseService.TAG, "This event is not available in the Firebase event map: $eventName")
            return
        }
        Log.w(TAG, "trackCustomEvent")
        val bundle = Bundle()
        for ((key, value) in payload) {
            when (value) {
                is Int -> bundle.putInt(key, value)
                else -> bundle.putString(key, value.toString())
            }
        }
        Analytics?.logEvent(eventName, bundle)
        Log.w(TAG, "trackCustomEvent complete")
    }
}