package com.noctuagames.sdk

import android.content.Context
import android.util.Log
import com.adjust.sdk.Adjust
import com.adjust.sdk.AdjustAdRevenue
import com.adjust.sdk.AdjustConfig
import com.adjust.sdk.AdjustAttribution
import com.adjust.sdk.AdjustEvent

data class NoctuaAdjustConfig(
    val appToken: String,
    val environment: String?,
    val eventMap: Map<String, String>,
)

class AdjustTracker(private var config: NoctuaAdjustConfig) {
    companion object {
        private const val TAG = "NoctuaProxyTracker"
    }
    var adjustContext: Context? = null;
    var adjustConfig: AdjustConfig? = null;
    var adjustMetadata: MutableMap<String, String>? = null;
    var adjustAttribution: AdjustAttribution? = null;
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

    fun onCreate(context: Context, config: NoctuaAdjustConfig) {
        Log.w(TAG, "AdjustTracker.onCreate")
        adjustContext = context
        val environment = if (config.environment.isNullOrEmpty()) {
            AdjustConfig.ENVIRONMENT_SANDBOX
        } else {
            config.environment
        }

        Log.w(TAG, "Adjust initialization")
        Log.w(TAG, config.appToken)
        adjustConfig = AdjustConfig(context, config.appToken, environment)

        loadMetadata()

        Adjust.onCreate(adjustConfig)
    }

    fun onResume() {
        Adjust.onResume()
    }

    fun onPause() {
        Adjust.onPause()
    }

    fun loadMetadata(): MutableMap<String, String>? {
        adjustMetadata = DeviceInfo(adjustContext, adjustConfig).getDeviceInfoMap(adjustContext)
        adjustAttribution = Adjust.getAttribution()
        adjustMetadata?.put("attribution_adid", adjustAttribution?.adid)
        adjustMetadata?.put("attribution_tracker_name", adjustAttribution?.trackerName)
        adjustMetadata?.put("attribution_tracker_token", adjustAttribution?.trackerToken)
        adjustMetadata?.put("attribution_adgroup", adjustAttribution?.adgroup)
        adjustMetadata?.put("attribution_network", adjustAttribution?.network)
        adjustMetadata?.put("attribution_campaign", adjustAttribution?.campaign)
        adjustMetadata?.put("attribution_clicklabel", adjustAttribution?.clickLabel)
        adjustMetadata?.put("attribution_cost_currency", adjustAttribution?.costCurrency)
        adjustMetadata?.put("attribution_cost_type", adjustAttribution?.costType)
        adjustMetadata?.put("attribution_creative", adjustAttribution?.creative)

        val adid = Adjust.getAdid()
        if (adid != null) {
            adjustMetadata?.put("adid", adid)
        }
        return adjustMetadata as MutableMap<String, String>?
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
        val adjustEvent = AdjustEvent(config.eventMap[eventName])

        for ((key, value) in payload) {
            adjustEvent.addCallbackParameter(key, value.toString())
        }

        Adjust.trackEvent(adjustEvent)
    }
}
