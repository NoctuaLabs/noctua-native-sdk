package com.noctuagames.sdk

import android.content.Context
import android.util.Log
import android.os.Bundle
import com.adjust.sdk.AdjustAdRevenue

import com.google.firebase.FirebaseApp
import com.google.firebase.analytics.FirebaseAnalytics

class FirebaseService() {
    companion object {
        private lateinit var firebaseContext: Context
        private val TAG = FirebaseService::class.simpleName
    }
    private lateinit var Analytics: FirebaseAnalytics

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

    private fun createFirebaseAnalyticsInstance(firebaseApp: FirebaseApp?): FirebaseAnalytics {
        // Use reflection to initialize FirebaseAnalytics for the secondary FirebaseApp
        return try {
            val clazz = Class.forName("com.google.firebase.analytics.FirebaseAnalytics")
            val instance = clazz.getDeclaredMethod("getInstance", Context::class.java, FirebaseApp::class.java)
                .invoke(null, this, firebaseApp)
            instance as FirebaseAnalytics
        } catch (e: Exception) {
            throw e
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
        val adRevenue = AdjustAdRevenue(source)
        adRevenue.setRevenue(revenue, currency)

        for ((key, value) in extraPayload) {
            adRevenue.addCallbackParameter(key, value.toString())
        }

        val bundle = Bundle().apply { // TODO do we need to add network/type/campaign here?
            putString("source", source)
            putDouble("ad_revenue", revenue)
            putString("currency", currency)
        }
        for ((key, value) in extraPayload) {
            bundle.putString(key, value.toString())
        }
        Analytics.logEvent("ad_revenue", bundle)
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
            bundle.putString(key, value.toString())
        }
        Analytics.logEvent(FirebaseAnalytics.Event.PURCHASE, bundle)
        Log.w(TAG, "Purchase event logged: $currency, $amount, $orderId, $extraPayload")
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        Log.w(TAG, "trackCustomEvent")
        val bundle = Bundle()
        for ((key, value) in payload) {
            bundle.putString(key, value.toString())
        }
        Analytics?.logEvent(eventName, bundle)
        Log.w(TAG, "trackCustomEvent complete")
    }
}