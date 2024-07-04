package com.noctuagg.sdk

import android.content.Context
import android.app.Activity
import com.adjust.sdk.Adjust
import com.adjust.sdk.AdjustEvent
import com.adjust.sdk.AdjustConfig
import org.apache.kafka.clients.producer.KafkaProducer
import org.apache.kafka.clients.producer.ProducerConfig
import org.apache.kafka.clients.producer.ProducerRecord
import org.apache.kafka.common.serialization.StringSerializer
import com.google.gson.Gson

data class InitParams(
    val productCode: String,
    val adjustAppToken: String,
    // TODO will be moved somewhere later
    val kafkaBootstrapServers: String,
    val kafkaTopic: String,
)

class SDK {
    private lateinit var productCode: String
    private lateinit var kafkaBootstrapServers: String
    private lateinit var kafkaTopic: String
    private lateinit var kafkaProducer: KafkaProducer<String, String>

    private val sdkVersion: String = "1.0.0"

    fun init(context: Context, params: InitParams) {
        this.productCode = params.productCode
        this.kafkaBootstrapServers = params.kafkaBootstrapServers
        this.kafkaTopic = params.kafkaTopic

        val appToken = params.adjustAppToken
        val environment = AdjustConfig.ENVIRONMENT_SANDBOX
        val config = AdjustConfig(context, appToken, environment)
        Adjust.onCreate(config)

        val props = mutableMapOf<String, Any>(
            ProducerConfig.BOOTSTRAP_SERVERS_CONFIG to kafkaBootstrapServers,
            ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG to StringSerializer::class.java.name,
            ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG to StringSerializer::class.java.name
        )
        kafkaProducer = KafkaProducer(props)
    }

    private fun checkInitialization() {
        if (!this::productCode.isInitialized) {
            throw IllegalStateException("SDK not initialized. Call init() first.")
        }
    }

    fun getSdkVersion(): String {
        checkInitialization();
        return sdkVersion
    }

    fun onResume() {
        Adjust.onResume()
    }

    fun onPause() {
        Adjust.onPause()
    }

    fun trackEvent(eventName: String) {
        checkInitialization();

        val adjustEvent = AdjustEvent(eventName)
        Adjust.trackEvent(adjustEvent)

        // Red panda
        val payload = mapOf("foo" to "bar", "adjustEventName" to eventName)
        sendToRedpanda(this.kafkaTopic, payload)
    }

    private fun sendToRedpanda(topic: String, payload: Any) {

        val gson = Gson()
        val jsonPayload = gson.toJson(payload)
        val record = ProducerRecord<String, String>(topic, jsonPayload)
        kafkaProducer.send(record)
    }
}
