package com.noctuagames.sdk

import android.content.Context
import android.util.Log
import android.os.Bundle
import com.google.firebase.FirebaseApp
import com.google.firebase.analytics.FirebaseAnalytics

data class FirebaseServiceConfig(
    val android: FirebbaseServiceAndroidConfig
)

data class FirebbaseServiceAndroidConfig(
    val disableCustomEvent: Boolean = false
)


class FirebaseService(private val config: FirebaseServiceConfig, context: Context) {
    private val TAG = this::class.simpleName
    private val analytics: FirebaseAnalytics

    init {
        if (FirebaseApp.getApps(context).isEmpty()) {
            if (FirebaseApp.initializeApp(context) == null) {
                throw Exception("Failed to initialize Firebase Analytics")
            }
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
        val bundle = Bundle().apply {
            putString(FirebaseAnalytics.Param.AD_SOURCE, source)
            putDouble(FirebaseAnalytics.Param.VALUE, revenue)
            putString(FirebaseAnalytics.Param.CURRENCY, currency)
            putExtras(extraPayload)
        }

        analytics.logEvent("ad_revenue", bundle)

        Log.d(
            TAG,
            "'ad_revenue' tracked: " +
                    "source: $source, " +
                    "revenue: $revenue, " +
                    "currency: $currency, " +
                    "extraPayload: $extraPayload"
        )
    }

    fun trackPurchase(
        orderId: String,
        amount: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        val bundle = Bundle().apply {
            putString(FirebaseAnalytics.Param.TRANSACTION_ID, orderId)
            putDouble(FirebaseAnalytics.Param.VALUE, amount)
            putString(FirebaseAnalytics.Param.CURRENCY, currency)
            putExtras(extraPayload)
        }

        analytics.logEvent(FirebaseAnalytics.Event.PURCHASE, bundle)

        Log.d(
            TAG,
            "'${FirebaseAnalytics.Event.PURCHASE}' tracked: " +
                    "currency: $currency, " +
                    "amount: $amount, " +
                    "orderId: $orderId, " +
                    "extraPayload $extraPayload"
        )
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        if (config.android.disableCustomEvent) {
            return
        }

        val eventName = payload["suffix"]?.let { "gf_${eventName}_${it}" } ?: "gf_$eventName"
        val payload = payload.filterKeys { it != "suffix" }

        analytics.logEvent(eventName, Bundle().apply { putExtras(payload) })

        Log.d(TAG, "'$eventName' (custom) tracked: payload: $payload")
    }
}