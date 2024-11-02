package com.noctuagames.sdk

import android.os.Build
import android.os.Bundle
import java.text.SimpleDateFormat
import java.time.Instant
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Date
import java.util.Locale
import kotlin.collections.iterator
import kotlin.jvm.java
import kotlin.text.compareTo
import kotlin.text.format

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
                        .apply { timeZone = java.util.TimeZone.getTimeZone("UTC") }
                        .format(value)
                }

                putString(key, isoDateString)
            }
            is Enum<*> -> putString(key, value.name)
            else -> putString(key, value.toString())
        }
    }
}