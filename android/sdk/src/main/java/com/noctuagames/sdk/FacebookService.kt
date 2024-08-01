package com.noctuagames.sdk

import android.content.Context
import android.util.Log
import android.os.Bundle
import android.app.Activity
import android.content.ContextWrapper
import com.adjust.sdk.AdjustAdRevenue

import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger
import java.util.Currency

/*
References:
- https://developers.facebook.com/docs/app-events/getting-started-app-events-android/
- https://developers.facebook.com/docs/app-events/reference
* */

data class FacebookServiceConfig(
    // Credentials are written in Android Resources
    val eventMap: Map<String, String>,
)

class FacebookService(private val config: FacebookServiceConfig) {
    companion object {
        private lateinit var facebookContext: Context
        private val TAG = FacebookService::class.simpleName
    }
    private lateinit var Analytics: AppEventsLogger

    init {
        if (config.eventMap.isEmpty()) {
            throw IllegalArgumentException("Event map for Facebook is not set in noctuaggconfig.json")
        }
        if (!config.eventMap.containsKey("ad_revenue")) {
            throw IllegalArgumentException("Event name for Facebook Purchase is not set in noctuaggconfig.json")
        }
        /* Facebook is using logPurchase to track purchase directly, no need to set specific event name for purchase
        if (!config.eventMap.containsKey("Purchase")) {
            throw IllegalArgumentException("Event name for Facebook Purchase is not set in noctuaggconfig.json")
        }
         */
    }

    fun Context.getActivity(): Activity? = when (this) {
        is Activity -> this
        is ContextWrapper -> baseContext.getActivity()
        else -> null
    }

    fun onCreate(context: Context) {
        facebookContext = context
        Log.w(TAG, "NoctuaFacbook.onCreate")
        Log.w(TAG, "Noctua's Facbook initialization")
        try {
            FacebookSdk.setAutoInitEnabled(true)
            FacebookSdk.fullyInitialize()
            FacebookSdk.setAdvertiserIDCollectionEnabled(true)
            facebookContext.getActivity()?.let {
                Analytics = AppEventsLogger.newLogger(it)
                Log.w(TAG, "Facbook Analytics initialized successfully")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing Facbook: ${e.message}", e)
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
        // No example from legacy codebase. Let's put the metadata inside the bundle.
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
        Analytics.logEvent(config.eventMap["ad_revenue"], bundle)
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

        // Put the metadata as is into the bundle, just like legacy codebase
        val bundle = Bundle()
        for ((key, value) in extraPayload) {
            when (value) {
                is Int -> bundle.putInt(key, value)
                else -> bundle.putString(key, value.toString())
            }
        }
        Analytics.logPurchase(
            purchaseAmount = amount.toBigDecimal(),
            currency = Currency.getInstance(currency),
            parameters = bundle
        )
        Log.w(TAG, "Purchase event logged: $currency, $amount, $orderId, $extraPayload")
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        if (!config.eventMap.containsKey(eventName)) {
            Log.w(TAG, "This event is not available in the Facebook event map: $eventName")
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
        Analytics.logEvent(config.eventMap[eventName], bundle)
    }
}