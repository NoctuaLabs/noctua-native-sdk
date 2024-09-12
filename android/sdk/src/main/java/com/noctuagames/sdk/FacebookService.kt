package com.noctuagames.sdk

import android.content.Context
import android.util.Log
import android.os.Bundle
import android.app.Activity
import android.content.ContextWrapper

import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger
import java.io.Serializable
import java.util.Currency

/*
References:
- https://developers.facebook.com/docs/app-events/getting-started-app-events-android/
- https://developers.facebook.com/docs/app-events/reference
* */

data class FacebookServiceConfig(
    val eventMap: Map<String, String>,
)

class FacebookService(private val config: FacebookServiceConfig, context: Context) {
    companion object {
        private val TAG = FacebookService::class.simpleName
    }

    private val eventsLogger: AppEventsLogger

    init {
        if (config.eventMap.isEmpty()) {
            throw IllegalArgumentException("Event map for Facebook is not set in noctuaggconfig.json")
        }
        if (!config.eventMap.containsKey("AdRevenue")) {
            throw IllegalArgumentException("Event name for Facebook Purchase is not set in noctuaggconfig.json")
        }

        FacebookSdk.setAutoInitEnabled(true)
        FacebookSdk.fullyInitialize()
        FacebookSdk.setAdvertiserIDCollectionEnabled(true)
        eventsLogger = AppEventsLogger.newLogger(context)

        Log.i(TAG, "FacebookService initialized")
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
            putExtras(extraPayload)
        }

        eventsLogger.logEvent(config.eventMap["AdRevenue"], bundle)
        Log.d(
            TAG,
            "Ad revenue event logged: Source: $source, Revenue: $revenue, Currency: $currency"
        )
    }

    fun trackPurchase(
        orderId: String,
        amount: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        // Put the metadata as is into the bundle, just like legacy codebase
        eventsLogger.logPurchase(
            purchaseAmount = amount.toBigDecimal(),
            currency = Currency.getInstance(currency),
            parameters = Bundle().apply {
                putString("transaction_id", orderId)
                putExtras(extraPayload)
            }
        )

        Log.d(TAG, "Purchase event logged: $currency, $amount, $orderId, $extraPayload")
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        if (!config.eventMap.containsKey(eventName)) {
            Log.w(TAG, "This event is not available in the Facebook event map: $eventName")
            return
        }

        eventsLogger.logEvent(config.eventMap[eventName], Bundle().apply { putExtras(payload) })
    }
}