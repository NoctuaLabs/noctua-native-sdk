package com.noctuagames.sdk

import android.content.Context
import android.util.Log
import com.google.gson.Gson
import java.io.IOException

data class NoctuaConfig(
    val productCode: String?,
    val adjust: AdjustServiceConfig?,
    val noctua: NoctuaServiceConfig?,
)

class Noctua {
    private lateinit var productCode: String
    private var adjust: AdjustService? = null
    private var noctua: NoctuaService? = null

    fun init(context: Context) {
        Log.w(TAG, "init")
        val config = loadAppConfig(context)

        if (config.productCode.isNullOrEmpty()) {
            throw IllegalArgumentException("productCode is not set in noctuagg.json")
        }

        this.productCode = config.productCode

        val adjustAvailable =
            try {
                Class.forName("com.adjust.sdk.Adjust")
                true
            } catch (e: ClassNotFoundException) {
                Log.w(TAG, "Adjust SDK is not found. Adjust tracking will be disabled.")
                false
            }

        if (adjustAvailable && config.adjust != null) {
            adjust = AdjustService(config.adjust)
            adjust?.onCreate(context)
        }

        noctua = config.noctua?.let {
            NoctuaService(it, context, adjust != null)
        }

        noctua?.trackFirstInstall()
    }

    private fun checkInit() {
        if (!this::productCode.isInitialized) {
            throw IllegalArgumentException("SDK not initialized. Call init() first.")
        }
    }

    fun onResume() {
        checkInit();
        adjust?.onResume()
    }

    fun onPause() {
        checkInit();
        adjust?.onPause()
    }

    fun trackCustomEvent(eventName: String, payload: MutableMap<String, Any> = mutableMapOf()) {
        checkInit()
        adjust?.trackCustomEvent(eventName, payload)
        noctua?.trackCustomEvent(eventName, payload)
    }

    fun trackAdRevenue(
        source: String,
        revenue: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        checkInit();
        adjust?.trackAdRevenue(source, revenue, currency, extraPayload)
        noctua?.trackAdRevenue(source, revenue, currency, extraPayload)
    }

    fun trackPurchase(
        orderId: String,
        amount: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        checkInit();

        adjust?.trackPurchase(orderId, amount, currency, extraPayload)
        noctua?.trackPurchase(orderId, amount, currency, extraPayload)
    }

    companion object {
        private val TAG = Noctua::class.simpleName
        private val instance = Noctua()

        fun init(context: Context) {
            Log.w(TAG, "init")
            instance.init(context)
        }

        fun onResume() {
            instance.onResume()
        }

        fun onPause() {
            instance.onPause()
        }

        fun trackAdRevenue(
            source: String,
            revenue: Double,
            currency: String,
            extraPayload: MutableMap<String, Any> = mutableMapOf()
        ) {
            instance.trackAdRevenue(source, revenue, currency, extraPayload)
        }

        fun trackPurchase(
            orderId: String,
            amount: Double,
            currency: String,
            extraPayload: MutableMap<String, Any> = mutableMapOf()
        ) {
            instance.trackPurchase(orderId, amount, currency, extraPayload)
        }

        fun trackCustomEvent(eventName: String, payload: MutableMap<String, Any> = mutableMapOf()) {
            instance.trackCustomEvent(eventName, payload)
        }
    }
}

fun loadAppConfig(context: Context): NoctuaConfig {
    try {
        context.assets.open("noctuagg.json").use {
            val buffer = ByteArray(it.available())
            it.read(buffer)
            val json = String(buffer)

            return Gson().fromJson(json, NoctuaConfig::class.java)
        }
    } catch (e: IOException) {
        throw IllegalArgumentException("Failed to load noctuagg.json", e)
    }
}