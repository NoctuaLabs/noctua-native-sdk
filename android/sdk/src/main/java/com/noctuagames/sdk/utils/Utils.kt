package com.noctuagames.sdk.utils

import android.content.Context
import android.os.Build
import android.os.Bundle
import com.google.gson.GsonBuilder
import com.noctuagames.sdk.models.NoctuaConfig
import java.io.IOException
import java.text.SimpleDateFormat
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.collections.iterator

fun Bundle.putExtras(extraPayload: Map<String, Any?>) {
    for ((key, value) in extraPayload) {
        when (value) {
            is Short -> putShort(key, value)
            is Int -> putInt(key, value)
            is Long -> putLong(key, value)
            is Float -> putFloat(key, value)
            is Double -> putDouble(key, value)
            is String -> putString(key, value)
            is Boolean -> putString(key, value.toString())
            is Date -> {
                val isoDateString = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    value.toInstant().atOffset(ZoneOffset.UTC).format(DateTimeFormatter.ISO_INSTANT)
                } else {
                    SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
                        .apply { timeZone = TimeZone.getTimeZone("UTC") }
                        .format(value)
                }

                putString(key, isoDateString)
            }
            is Enum<*> -> putString(key, value.name)
            else -> putString(key, value.toString())
        }
    }
}

fun Double?.toSafeJsonDouble(): Double? {
    return if (this == null || this.isNaN() || this.isInfinite()) {
        null
    } else {
        this
    }
}

fun loadConfig(context: Context): NoctuaConfig {
    return try {
        context.assets.open("noctuagg.json").use { inputStream ->
            val buffer = ByteArray(inputStream.available())
            inputStream.read(buffer)

            val json = String(buffer)

            val gson = GsonBuilder().create()
            gson.fromJson(json, NoctuaConfig::class.java)
        }
    } catch (e: IOException) {
        throw IllegalArgumentException("Failed to load noctuagg.json", e)
    }
}
