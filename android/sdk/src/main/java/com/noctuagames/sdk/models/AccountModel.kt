package com.noctuagames.sdk.models

data class Account(
    val userId: Long,
    val gameId: Long,
    val rawData: String,
    val lastUpdated: Long
) {
    constructor(userId: Long, gameId: Long, rawData: String) : this(
        userId = userId,
        gameId = gameId,
        rawData = rawData,
        lastUpdated = System.currentTimeMillis()
    )
}