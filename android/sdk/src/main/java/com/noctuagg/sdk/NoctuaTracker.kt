package com.noctuagg.sdk

import com.google.gson.Gson
import org.apache.kafka.clients.producer.KafkaProducer
import org.apache.kafka.clients.producer.ProducerConfig
import org.apache.kafka.clients.producer.ProducerRecord
import org.apache.kafka.common.serialization.StringSerializer

data class NoctuaConfig(
    val kafkaBootstrapServers: String,
    val kafkaTopic: String,
)

class NoctuaTracker(private val config: NoctuaConfig) {
    private val kafkaTopic = config.kafkaTopic
    private val kafkaProducer: KafkaProducer<String, String>

    init {
        if (config.kafkaBootstrapServers.isEmpty()) {
            throw IllegalArgumentException("Kafka bootstrap servers is not set in noctuaggconfig.json")
        }

        if (config.kafkaTopic.isEmpty()) {
            throw IllegalArgumentException("Kafka topic is not set in noctuaggconfig.json")
        }

        kafkaProducer = KafkaProducer(
            mutableMapOf<String, Any>(
                ProducerConfig.BOOTSTRAP_SERVERS_CONFIG to config.kafkaBootstrapServers,
                ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG to StringSerializer::class.java.name,
                ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG to StringSerializer::class.java.name
            )
        )
    }

    fun trackAdRevenue(source: String, revenue: Double, currency: String) {
        val payload = mapOf("source" to source, "revenue" to revenue, "currency" to currency)
        sendEvent("AdRevenue", payload)
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

        val payload = mapOf("orderId" to orderId, "amount" to amount, "currency" to currency)
        sendEvent("Purchase", payload)
    }

    fun trackCustomEvent(eventName: String, payload: Map<String, Any> = emptyMap()) {
        sendEvent(eventName, payload)
    }

    private fun sendEvent(eventName: String, payload: Map<String, Any>) {
        val gson = Gson()
        val jsonPayload = gson.toJson(payload)
        val record = ProducerRecord(kafkaTopic, eventName, jsonPayload)
        kafkaProducer.send(record)
    }
}