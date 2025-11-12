package com.noctuagames.sdk

import android.content.Context
import android.util.Log
import com.adjust.sdk.Adjust
import com.adjust.sdk.AdjustAdRevenue
import com.adjust.sdk.AdjustConfig
import com.adjust.sdk.AdjustEvent

data class AdjustServiceConfig(
    val android: AdjustServiceAndroidConfig?,
)

data class AdjustServiceAndroidConfig(
    val appToken: String,
    val environment: String?,
    val customEventDisabled: Boolean = false,
    val eventMap: Map<String, String>?,
)

internal class AdjustService(private val config: AdjustServiceAndroidConfig, context: Context) {
    private val TAG = this::class.simpleName

    init {
        if (config.appToken.isEmpty()) {
            throw IllegalArgumentException("App token is not set")
        }

        if (config.eventMap.isNullOrEmpty()) {
            throw IllegalArgumentException("Event map is not set")
        }

        if (!config.eventMap.containsKey("purchase")) {
            throw IllegalArgumentException("Event token for purchase is not set")
        }

        val environment = if (config.environment.isNullOrEmpty()) {
            AdjustConfig.ENVIRONMENT_SANDBOX
        } else {
            config.environment
        }

        val adjustConfig = AdjustConfig(context, config.appToken, environment)
        Adjust.initSdk(adjustConfig)
        Log.i(TAG, "Adjust SDK initialized successfully")
    }

    fun onResume() {
        Adjust.onResume()
    }

    fun onPause() {
        Adjust.onPause()
    }

    fun onOnline() {
        Adjust.switchBackToOnlineMode()
    }

    fun onOffline() {
        Adjust.switchToOfflineMode()
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
        val event = AdjustEvent(config.eventMap?.get("purchase") ?: "")
        event.setRevenue(amount, currency)
        event.orderId = orderId

        for ((key, value) in extraPayload) {
            event.addCallbackParameter(key, value.toString())
        }

        Adjust.trackEvent(event)
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        if (config.customEventDisabled) {
            return
        }

        if (config.eventMap.isNullOrEmpty()) {
            Log.e(TAG, "Event map is not set")
            return
        }

        if (!config.eventMap.containsKey(eventName)) {
            Log.e(TAG, "$eventName event token is not available in the event map")
            return
        }

        val adjustEvent = AdjustEvent(config.eventMap?.get(eventName) ?: "")

        for ((key, value) in payload) {
            adjustEvent.addCallbackParameter(key, value.toString())
        }

        Adjust.trackEvent(adjustEvent)
    }

    fun trackCustomEventWithRevenue(eventName: String, revenue: Double, currency: String, payload: Map<String, Any> = emptyMap()) {
        if (config.customEventDisabled) {
            return
        }

        if (config.eventMap.isNullOrEmpty()) {
            Log.e(TAG, "Event map is not set")
            return
        }

        if (!config.eventMap.containsKey(eventName)) {
            Log.e(TAG, "$eventName event token is not available in the event map")
            return
        }

        val adjustEvent = AdjustEvent(config.eventMap?.get(eventName) ?: "")
        payload + ("revenue" to revenue)
        payload + ("currency" to currency)

        for ((key, value) in payload) {
            adjustEvent.addCallbackParameter(key, value.toString())
        }

        Adjust.trackEvent(adjustEvent)
    }
}