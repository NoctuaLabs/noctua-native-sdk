package com.noctuagg.sdk

import android.content.Context
import com.adjust.sdk.Adjust
import com.adjust.sdk.AdjustAdRevenue
import com.adjust.sdk.AdjustConfig
import com.adjust.sdk.AdjustEvent
import com.adjust.sdk.LogLevel

data class NoctuaAdjustConfig(
    val appToken: String,
    val environment: String?,
    val eventMap: Map<String, String>,
)

class AdjustTracker(private var config: NoctuaAdjustConfig) {
    init {
        if (config.appToken.isEmpty()) {
            throw IllegalArgumentException("App token is not set in noctuaggconfig.json")
        }

        if (config.eventMap.isEmpty()) {
            throw IllegalArgumentException("Event map is not set in noctuaggconfig.json")
        }

        if (!config.eventMap.containsKey("Purchase")) {
            throw IllegalArgumentException("Event name for Purchase is not set in noctuaggconfig.json")
        }
    }

    fun onCreate(context: Context, adjustConfig: NoctuaAdjustConfig) {
        val environment = if (adjustConfig.environment.isNullOrEmpty()) {
            AdjustConfig.ENVIRONMENT_SANDBOX
        } else {
            adjustConfig.environment
        }

        Adjust.onCreate(AdjustConfig(context, adjustConfig.appToken, environment))
    }

    fun onResume() {
        Adjust.onResume()
    }

    fun onPause() {
        Adjust.onPause()
    }

    fun trackAdRevenue(source: String, revenue: Double, currency: String) {
        val adRevenue = AdjustAdRevenue(source)
        adRevenue.setRevenue(revenue, currency)
        Adjust.trackAdRevenue(adRevenue)
    }

    fun trackPurchase(orderId: String, amount: Double, currency: String) {
        if (orderId.isEmpty()) {
            throw IllegalArgumentException("orderId is not set")
        }

        if (amount <= 0) {
            throw IllegalArgumentException("revenue is negative or zero")
        }

        if (currency.isEmpty()) {
            throw IllegalArgumentException("currency is not set")
        }

        val event = AdjustEvent(config.eventMap["Purchase"])
        event.setRevenue(amount, currency)
        event.orderId = orderId
        Adjust.trackEvent(event)
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        val adjustEvent = AdjustEvent(eventName)

        for ((key, value) in payload) {
            adjustEvent.addCallbackParameter(key, value.toString())
        }

        Adjust.trackEvent(adjustEvent)
    }
}