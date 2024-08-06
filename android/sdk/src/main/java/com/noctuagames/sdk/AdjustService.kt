package com.noctuagames.sdk

import android.content.Context
import android.util.Log
import com.adjust.sdk.Adjust
import com.adjust.sdk.AdjustAdRevenue
import com.adjust.sdk.AdjustConfig
import com.adjust.sdk.AdjustEvent

data class AdjustServiceConfig(
    val appToken: String,
    val environment: String?,
    val eventMap: Map<String, String>,
)

internal class AdjustService(private val config: AdjustServiceConfig) {
    private lateinit var context: Context
    companion object {
        private val TAG = AdjustService::class.simpleName
    }

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

    fun onCreate(context: Context) {
        Log.w(TAG, "AdjustTracker.onCreate")
        this.context = context
        val environment = if (config.environment.isNullOrEmpty()) {
            AdjustConfig.ENVIRONMENT_SANDBOX
        } else {
            config.environment
        }

        Log.w(TAG, "Adjust initialization")
        val adjustConfig = AdjustConfig(context, config.appToken, environment)

        Adjust.onCreate(adjustConfig)
    }

    fun onResume() {
        Adjust.onResume()
    }

    fun onPause() {
        Adjust.onPause()
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

        Adjust.trackAdRevenue(adRevenue)
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

        val event = AdjustEvent(config.eventMap["Purchase"])
        event.setRevenue(amount, currency)
        event.orderId = orderId

        for ((key, value) in extraPayload) {
            event.addCallbackParameter(key, value.toString())
        }

        Adjust.trackEvent(event)
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        if (!config.eventMap.containsKey(eventName)) {
            Log.w(AdjustService.TAG, "This event is not available in the Adjust event map: $eventName")
            return
        }
        val adjustEvent = AdjustEvent(config.eventMap[eventName])

        for ((key, value) in payload) {
            adjustEvent.addCallbackParameter(key, value.toString())
        }

        Adjust.trackEvent(adjustEvent)
    }

}