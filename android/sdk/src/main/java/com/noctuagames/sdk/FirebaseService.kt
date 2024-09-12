package com.noctuagames.sdk

import android.content.Context
import android.util.Log
import android.os.Bundle
import com.google.firebase.FirebaseApp

import com.google.firebase.analytics.FirebaseAnalytics

data class FirebaseServiceConfig(
    val eventMap: Map<String, String>,
)


class FirebaseService(private val config: FirebaseServiceConfig, context: Context) {
    private val analytics: FirebaseAnalytics

    init {
        if (config.eventMap.isEmpty()) {
            throw IllegalArgumentException("Event map config for Firebase is not set")
        }
        if (FirebaseApp.getApps(context).isEmpty()) {
            FirebaseApp.initializeApp(context)
        }

        analytics = FirebaseAnalytics.getInstance(context)

        Log.i(TAG, "Firebase Analytics initialized successfully")
    }

    fun trackAdRevenue(
        source: String,
        revenue: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        val eventName = config.eventMap["AdRevenue"] ?: "ad_revenue"

        val bundle = Bundle().apply {
            putString("source", source)
            putDouble("ad_revenue", revenue)
            putString("currency", currency)
            putExtras(extraPayload)
        }

        analytics.logEvent(eventName, bundle)
        Log.d(
            TAG,
            "$eventName event logged: source: $source, revenue: $revenue, currency: $currency"
        )
    }

    fun trackPurchase(
        orderId: String,
        amount: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        val bundle = Bundle().apply {
            putString(FirebaseAnalytics.Param.CURRENCY, currency)
            putDouble(FirebaseAnalytics.Param.VALUE, amount)
            putString(FirebaseAnalytics.Param.TRANSACTION_ID, orderId)
            putExtras(extraPayload)
        }

        analytics.logEvent(FirebaseAnalytics.Event.PURCHASE, bundle)
        Log.d(
            TAG,
            "${FirebaseAnalytics.Event.PURCHASE} event logged: " +
                    "currency: $currency, " +
                    "amount: $amount, " +
                    "orderId: $orderId, " +
                    "extraPayload $extraPayload"
        )
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        val eventKey = config.eventMap[eventName] ?: eventName

        analytics.logEvent(eventKey, Bundle().apply { putExtras(payload) })
        Log.d(TAG, "$eventName event logged with payload: $payload")
    }

    companion object {
        private val TAG = FirebaseService::class.simpleName
    }
}