package com.noctuagames.sdk

import android.os.Bundle
import java.io.Serializable

fun Bundle.putExtras(extraPayload: Map<String, Any?>) {
    for ((key, value) in extraPayload) {
        when (value) {
            is Boolean -> putBoolean(key, value)
            is Int -> putInt(key, value)
            is Double -> putDouble(key, value)
            is Long -> putLong(key, value)
            is String -> putString(key, value)
            is Serializable -> putSerializable(key, value)
            else -> putString(key, value.toString())
        }
    }
}