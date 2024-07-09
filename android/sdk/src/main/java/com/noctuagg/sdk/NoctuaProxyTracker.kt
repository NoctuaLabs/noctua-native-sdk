package com.noctuagg.sdk

import android.content.Context
import android.content.SharedPreferences
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
        private const val PREFS_NAME = "NoctuaProxyTrackerPrefs"
        private const val KEY_FIRST_INSTALL = "isFirstInstall"
    }

    private lateinit var productCode: String
    private var adjustTracker: AdjustTracker? = null
    private var noctuaTracker: NoctuaTracker? = null
    private var appVersion: String = ""

    fun init(context: Context) {
        Log.w(TAG, "NoctuaProxyTracker.init")
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

        // NoctuaTracker does not need any config
        noctuaTracker = config.noctua?.let { NoctuaTracker(it) }

        val sharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val isFirstInstall = sharedPreferences.getBoolean(KEY_FIRST_INSTALL, true)
        if (isFirstInstall) {
            Log.w(TAG, "This is the first install.")
            val additionalPayload = loadAdjustMetadata()
            if (additionalPayload != null) {
                noctuaTracker?.trackCustomEvent("install", additionalPayload)
            }

            // Mark as not first install
            sharedPreferences.edit().putBoolean(KEY_FIRST_INSTALL, false).apply()
        } else {
            Log.w(TAG, "This is not the first install.")
        }
    }

    fun setAppVersion(version: String) {
        appVersion = version
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

    fun loadAdjustMetadata(): Map<String, String>? {
        val metadata = adjustTracker?.loadMetadata()?.toSortedMap()
        if (metadata != null) {
            for ((key, value) in metadata) {
                Log.w(TAG, "$key: $value")
            }
        }
        return metadata?.toMap()
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        checkInit()
        adjustTracker?.trackCustomEvent(eventName, payload)

        // Internal
        val additionalPayload = adjustTracker!!.adjustMetadata
        additionalPayload!!.plus(payload)
        additionalPayload.put("app_version", appVersion)
        noctuaTracker?.trackCustomEvent(eventName, additionalPayload)
    }

    fun trackAdRevenue(source: String, revenue: Double, currency: String) {
        checkInit();
        adjustTracker?.trackAdRevenue(source, revenue, currency)

        // Internal
        val adjustDeviceInfoMap = adjustTracker!!.adjustMetadata
        val additionalPayload = adjustDeviceInfoMap!!.toMutableMap()
        additionalPayload.put("app_version", appVersion)
        noctuaTracker?.trackAdRevenue(source, revenue, currency, additionalPayload)
    }

    fun trackPurchase(orderId: String, amount: Double, currency: String) {
        checkInit();

        adjustTracker?.trackPurchase(orderId, amount, currency)

        // Internal
        val adjustDeviceInfoMap = adjustTracker!!.adjustMetadata
        val additionalPayload = adjustDeviceInfoMap!!.toMutableMap()
        additionalPayload.put("app_version", appVersion)
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