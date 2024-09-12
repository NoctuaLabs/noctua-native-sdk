package com.noctuagames.sdk

import android.content.Context
import android.util.Log
import com.adjust.sdk.Adjust
import com.google.gson.Gson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody

data class NoctuaServiceConfig(
    val trackerURL: String,
)

internal class NoctuaService(
    config: NoctuaServiceConfig?,
    private val context: Context,
    private val withAdjust: Boolean = false
) {
    private val trackerURL =
        config?.trackerURL ?: "https://kafka-proxy-poc.noctuaprojects.com/api/v1/events"

    private val deviceInfo = DeviceInfo(context).getDeviceInfoMap()

    fun trackFirstInstall(extraPayload: MutableMap<String, Any> = mutableMapOf()) {
        val sharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val isFirstInstall = sharedPreferences.getBoolean(KEY_FIRST_INSTALL, true)
        if (isFirstInstall) {
            Log.d(TAG, "This is the first install.")

            trackCustomEvent("Install", extraPayload.toMutableMap())

            // Mark as not first install
            sharedPreferences.edit().putBoolean(KEY_FIRST_INSTALL, false).apply()
        } else {
            Log.d(TAG, "This is not the first install.")
        }
    }

    fun trackAdRevenue(
        source: String,
        revenue: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        extraPayload["source"] = source
        extraPayload["revenue"] = revenue
        extraPayload["currency"] = currency

        sendEvent("AdRevenue", extraPayload)
    }

    fun trackPurchase(
        orderId: String,
        amount: Double,
        currency: String,
        extraPayload: MutableMap<String, Any> = mutableMapOf()
    ) {
        extraPayload["orderId"] = orderId
        extraPayload["amount"] = amount
        extraPayload["currency"] = currency

        sendEvent("Purchase", extraPayload)
    }

    fun trackCustomEvent(eventName: String, payload: MutableMap<String, Any> = mutableMapOf()) {
        sendEvent(eventName, payload)
    }

    private fun sendEvent(eventName: String, payload: MutableMap<String, Any>) {
        payload["event_name"] = eventName
        payload.putAll(deviceInfo)

        if (withAdjust) {
            payload.putAllAdjustMetadata()
        }

        Log.d(TAG, "Sending event: $payload")

        CoroutineScope(Dispatchers.IO).launch {
            val client = OkHttpClient()
            val json = Gson().toJson(payload)

            val mediaType = "application/json; charset=utf-8".toMediaTypeOrNull()
            val body: RequestBody = json.toRequestBody(mediaType)

            val request = Request.Builder()
                .url(trackerURL)
                .post(body)
                .build()

            try {
                val response = client.newCall(request).execute()
                withContext(Dispatchers.Main) {
                    if (response.isSuccessful) {
                        Log.d(TAG, "Event sent successfully: ${response.body?.string()}")
                    } else {
                        Log.w(TAG, "Failed to send event: ${response.body?.string()}")
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private companion object {
        private val TAG = NoctuaService::class.simpleName
        private const val PREFS_NAME = "NoctuaTrackerPrefs"
        private const val KEY_FIRST_INSTALL = "isFirstInstall"
    }
}

private fun MutableMap<String, Any>.putAllAdjustMetadata() {
    Adjust.getAttribution()?.let {
        this["attribution_adid"] = it.adid
        this["attribution_tracker_name"] = it.trackerName
        this["attribution_tracker_token"] = it.trackerToken
        this["attribution_adgroup"] = it.adgroup
        this["attribution_network"] = it.network
        this["attribution_campaign"] = it.campaign
        this["attribution_clicklabel"] = it.clickLabel
        this["attribution_cost_currency"] = it.costCurrency
        this["attribution_cost_type"] = it.costType
        this["attribution_creative"] = it.creative
    }

    this["adid"] = Adjust.getAdid()
}