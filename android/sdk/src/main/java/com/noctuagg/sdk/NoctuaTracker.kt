package com.noctuagg.sdk

import android.util.Log
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

data class NoctuaConfig(
    val trackerURL: String,
)

class NoctuaTracker(private val config: NoctuaConfig) {
    private var trackerURL: String = ""

    init {
        if (config.trackerURL.isEmpty()) {
            trackerURL = "https://kafka-proxy-poc.noctuaprojects.com/api/v1/events"
        } else {
            trackerURL = config.trackerURL
        }
    }

    fun trackAdRevenue(source: String, revenue: Double, currency: String, additionalPayload: Map<String, Any> = emptyMap()) {
        val payload = mapOf("source" to source, "revenue" to revenue, "currency" to currency)
        payload.plus(additionalPayload)
        sendEvent("AdRevenue", payload)
    }

    fun trackPurchase(orderId: String, amount: Double, currency: String, additionalPayload: Map<String, Any> = emptyMap()) {
        if (orderId.isEmpty()) {
            throw IllegalArgumentException("orderId is not set")
        }

        if (amount <= 0) {
            throw IllegalArgumentException("revenue is negative or zero")
        }

        if (currency.isEmpty()) {
            throw IllegalArgumentException("currency is not set")
        }

        val payload = mapOf("orderId" to orderId, "amount" to amount, "currency" to currency)
        payload.plus(additionalPayload)
        sendEvent("Purchase", payload)
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        sendEvent(eventName, payload)
    }

    private fun sendEvent(eventName: String, params: Map<String, Any>) {
        CoroutineScope(Dispatchers.IO).launch {
            val client = OkHttpClient()
            val json = Gson().toJson(params)

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
                        Log.w("NoctuaProxyTracker", "Event sent successfully: ${response.body!!.string()}")
                    } else {
                        Log.w("NoctuaProxyTracker", "Failed to send event: ${response.body!!.string()}")
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}