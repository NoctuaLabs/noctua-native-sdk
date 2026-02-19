package com.noctuagames.sdk.models

import com.adjust.sdk.AdjustAttribution
import com.noctuagames.sdk.utils.toSafeJsonDouble
import org.json.JSONObject

data class AdjustServiceConfig(
    val android: AdjustServiceAndroidConfig?,
)

data class AdjustServiceAndroidConfig(
    val appToken: String,
    val environment: String?,
    val customEventDisabled: Boolean = false,
    val eventMap: Map<String, String>?,
)

data class NoctuaAdjustAttribution(
    val trackerToken: String? = "",
    val trackerName: String? = "",
    val network: String? = "",
    val campaign: String? = "",
    val adGroup: String? = "",
    val creative: String? = "",
    val clickLabel: String? = "",
    val costType: String? = "",
    val costAmount: Double? = 0.0,
    val costConcurrency: String? = "",
    val fbInstallReferrer: String? = ""
)

fun NoctuaAdjustAttribution?.toJsonString(): String {
    if (this == null) return "{}"

    return JSONObject().apply {
        put("trackerToken", trackerToken)
        put("trackerName", trackerName)
        put("network", network)
        put("campaign", campaign)
        put("adGroup", adGroup)
        put("creative", creative)
        put("clickLabel", clickLabel)
        put("costType", costType)
        put("costAmount", costAmount.toSafeJsonDouble())
        put("costConcurrency", costConcurrency)
        put("fbInstallReferrer", fbInstallReferrer)
    }.toString()
}

fun AdjustAttribution.toNoctuaAdjustAttribution(): NoctuaAdjustAttribution {
    return NoctuaAdjustAttribution(
        trackerToken = this.trackerToken,
        trackerName = this.trackerName,
        network = this.network,
        campaign = this.campaign,
        adGroup = this.adgroup,
        creative = this.creative,
        clickLabel = this.clickLabel,
        costType = this.costType,
        costAmount = this.costAmount,
        costConcurrency = this.costCurrency,
        fbInstallReferrer = this.fbInstallReferrer
    )
}