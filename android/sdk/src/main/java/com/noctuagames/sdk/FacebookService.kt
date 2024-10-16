package com.noctuagames.sdk

import android.content.Context
import android.os.Bundle
import android.util.Log
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsConstants
import com.facebook.appevents.AppEventsLogger
import java.util.Currency

/*
References:
- https://developers.facebook.com/docs/app-events/getting-started-app-events-android/
- https://developers.facebook.com/docs/app-events/reference
* */

data class FacebookServiceConfig(
    val enableDebug: Boolean = false,
    val advertiserIdCollectionEnabled: Boolean = true,
    val autoLogAppEventsEnabled: Boolean = true,
    val disableCustomEvent: Boolean = false,
    val eventMap: Map<String, String> = mapOf(),
)

class FacebookService(private val config: FacebookServiceConfig, context: Context) {
    private val TAG = this::class.simpleName
    private val eventsLogger: AppEventsLogger

    init {
        if (config.enableDebug) {
            FacebookSdk.setIsDebugEnabled(true)
            FacebookSdk.addLoggingBehavior(com.facebook.LoggingBehavior.APP_EVENTS)
        } else {
            FacebookSdk.setIsDebugEnabled(false)
            FacebookSdk.removeLoggingBehavior(com.facebook.LoggingBehavior.APP_EVENTS)
        }

        FacebookSdk.setAutoLogAppEventsEnabled(config.autoLogAppEventsEnabled)
        FacebookSdk.setAdvertiserIDCollectionEnabled(config.advertiserIdCollectionEnabled)
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
        val eventName = config.eventMap["AdRevenue"] ?: "ad_revenue"

        val bundle = Bundle().apply {
            putString("source", source)
            putDouble("ad_revenue", revenue)
            putString("currency", currency)
            putExtras(extraPayload)
        }

        eventsLogger.logEvent(eventName, bundle)

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
        if (config.disableCustomEvent) {
            return
        }

        if (!config.eventMap.containsKey(eventName)) {
            Log.e(TAG, "$eventName event is not available in the event map")
            return
        }

        eventsLogger.logEvent(config.eventMap[eventName], Bundle().apply { putExtras(payload) })

        Log.d(TAG, "'$eventName' (custom) tracked: payload: $payload")
    }
}