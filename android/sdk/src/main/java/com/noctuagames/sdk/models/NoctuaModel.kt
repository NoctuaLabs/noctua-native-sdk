package com.noctuagames.sdk.models

data class NoctuaServiceConfig(
    val nativeInternalTrackerEnabled: Boolean?
)
data class NoctuaConfig(
    val clientId: String?,
    val gameId: Long?,
    val adjust: AdjustServiceConfig?,
    val firebase: FirebaseServiceConfig?,
    val facebook: FacebookServiceConfig?,
    val noctua: NoctuaServiceConfig?
)