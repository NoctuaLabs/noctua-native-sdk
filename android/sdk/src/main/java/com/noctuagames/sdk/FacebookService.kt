package com.noctuagames.sdk

import android.content.Context
import android.os.Bundle
import android.util.Log
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsConstants
import com.facebook.appevents.AppEventsLogger
import java.io.Serializable
import java.util.Currency
import java.util.Date
import kotlin.collections.component1
import kotlin.collections.component2
import kotlin.collections.iterator

/*
References:
- https://developers.facebook.com/docs/app-events/getting-started-app-events-android/
- https://developers.facebook.com/docs/app-events/reference
* */

data class FacebookServiceConfig(
    val android: FacebookServiceAndroidConfig
)

data class FacebookServiceAndroidConfig(
    val enableDebug: Boolean = false,
    val advertiserIdCollectionEnabled: Boolean = true,
    val autoLogAppEventsEnabled: Boolean = true,
    val disableCustomEvent: Boolean = false
)

class FacebookService(private val config: FacebookServiceConfig, context: Context) {
    private val TAG = this::class.simpleName
    private val eventsLogger: AppEventsLogger

    init {
        if (config.android.enableDebug) {
            FacebookSdk.setIsDebugEnabled(true)
            FacebookSdk.addLoggingBehavior(com.facebook.LoggingBehavior.APP_EVENTS)
        } else {
            FacebookSdk.setIsDebugEnabled(false)
            FacebookSdk.removeLoggingBehavior(com.facebook.LoggingBehavior.APP_EVENTS)
        }

        FacebookSdk.setAutoLogAppEventsEnabled(config.android.autoLogAppEventsEnabled)
        FacebookSdk.setAdvertiserIDCollectionEnabled(config.android.advertiserIdCollectionEnabled)
        FacebookSdk.setAutoInitEnabled(true)
        FacebookSdk.fullyInitialize()

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

        eventsLogger.logEvent("ad_revenue", bundle)

        Log.d(
            TAG,
            "Ad revenue tracked: " +
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
        eventsLogger.logPurchase(
            purchaseAmount = amount.toBigDecimal(),
            currency = Currency.getInstance(currency),
            parameters = Bundle().apply {
                putString(AppEventsConstants.EVENT_PARAM_ORDER_ID, orderId)
                putExtras(extraPayload)
            }
        )

        Log.d(
            TAG,
            "Purchase tracked: " +
                    "orderId: $orderId, " +
                    "amount: $amount, " +
                    "currency: $currency, " +
                    "extraPayload: $extraPayload"
        )
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        if (config.android.disableCustomEvent) {
            return
        }

        val eventName = payload["suffix"]?.let { "fb_${eventName}_${it}" } ?: "fb_$eventName"
        val payload = payload.filterKeys { it != "suffix" }

        eventsLogger.logEvent(eventName, Bundle().apply { putExtras(payload) })

        Log.d(TAG, "'$eventName' (custom) tracked: payload: $payload")
    }
}