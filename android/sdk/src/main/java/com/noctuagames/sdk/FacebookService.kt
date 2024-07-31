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

class FacebookService() {
    companion object {
        private lateinit var facebookContext: Context
        private val TAG = FacebookService::class.simpleName
    }
    private lateinit var Analytics: AppEventsLogger

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
        val adRevenue = AdjustAdRevenue(source)
        adRevenue.setRevenue(revenue, currency)

        for ((key, value) in extraPayload) {
            adRevenue.addCallbackParameter(key, value.toString())
        }

        // TODO need to look up to legacy code base, what to put in here
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

        /* TODO need to look up to legacy code base, what to put in here
        val bundle = Bundle().apply {
            ???
        }
        for ((key, value) in extraPayload) {
            bundle.putString(key, value.toString())
        }
        * */
        Analytics.logPurchase(
            purchaseAmount = amount.toBigDecimal(),
            currency = Currency.getInstance(currency),
            //parameters = bundle
        )
        Log.w(TAG, "Purchase event logged: $currency, $amount, $orderId, $extraPayload")
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        Log.w(TAG, "trackCustomEvent")
        val bundle = Bundle()
        for ((key, value) in payload) {
            bundle.putString(key, value.toString())
        }
        Analytics.logEvent(eventName, bundle)
    }
}