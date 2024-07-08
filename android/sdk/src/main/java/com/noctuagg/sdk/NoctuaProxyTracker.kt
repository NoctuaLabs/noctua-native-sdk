package com.noctuagg.sdk

import android.content.Context
import android.util.Log
import com.google.gson.Gson
import java.io.IOException

data class NoctuaGGConfig(
    val productCode: String?,
    val adjust : NoctuaAdjustConfig?,
    val noctua : NoctuaConfig?,
)

class NoctuaProxyTracker {
    companion object {
        private const val TAG = "NoctuaProxyTracker"
    }

    private lateinit var productCode: String
    private var adjustTracker: AdjustTracker? = null
    private var noctuaTracker: NoctuaTracker? = null

    fun init(context: Context) {
        val config = loadAppConfig(context)

        if (config.productCode.isNullOrEmpty()) {
            throw IllegalArgumentException("productCode is not set in noctuagg.json")
        }

        this.productCode = config.productCode

        if (config.adjust != null) {
            adjustTracker = AdjustTracker(config.adjust)
            adjustTracker?.onCreate(context, config.adjust)
        } else {
            Log.w(TAG, "Adjust configuration is not set. Adjust tracking will be disabled.")
        }

        if (config.noctua != null) {
            noctuaTracker = NoctuaTracker(config.noctua)
        } else {
            Log.w(TAG, "Noctua configuration is not set. Noctua tracking will be disabled.")
        }
    }

    private fun checkInit() {
        if (!this::productCode.isInitialized) {
            throw IllegalArgumentException("SDK not initialized. Call init() first.")
        }
    }

    val sdkVersion: String = "0.1.0"

    fun onResume() {
        checkInit();

        adjustTracker?.onResume()
    }

    fun onPause() {
        checkInit();

        adjustTracker?.onPause()
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        checkInit();

        adjustTracker?.trackCustomEvent(eventName, payload)
        noctuaTracker?.trackCustomEvent(eventName, payload)
    }

    fun trackAdRevenue(source: String, revenue: Double, currency: String) {
        checkInit();

        adjustTracker?.trackAdRevenue(source, revenue, currency)
        noctuaTracker?.trackAdRevenue(source, revenue, currency)
    }

    fun trackPurchase(orderId: String, amount: Double, currency: String) {
        checkInit();

        adjustTracker?.trackPurchase(orderId, amount, currency)
        noctuaTracker?.trackPurchase(orderId, amount, currency)
    }
}

fun loadAppConfig(context: Context): NoctuaGGConfig {
    try {
        context.assets.open("noctuagg.json").use {
            val buffer = ByteArray(it.available())
            it.read(buffer)
            val json = String(buffer)

            return Gson().fromJson(json, NoctuaGGConfig::class.java)
        }
    } catch (e: IOException) {
        throw IllegalArgumentException("Failed to load noctuagg.json", e)
    }
}