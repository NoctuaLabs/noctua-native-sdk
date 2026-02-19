package com.noctuagames.sdk.models

data class FirebaseServiceConfig(
    val android: FirebaseServiceAndroidConfig?
)

data class FirebaseServiceAndroidConfig(
    val customEventDisabled: Boolean = false
)