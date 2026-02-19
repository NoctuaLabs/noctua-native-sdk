package com.noctuagames.sdk.models

data class FacebookServiceConfig(
    val android: FacebookServiceAndroidConfig?
)

data class FacebookServiceAndroidConfig(
    val enableDebug: Boolean = false,
    val advertiserIdCollectionEnabled: Boolean = true,
    val autoLogAppEventsEnabled: Boolean = true,
    val customEventDisabled: Boolean = false
)