package com.noctuagames.sdk.services

import android.app.Activity
import android.content.Context
import android.util.Log
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import com.google.android.play.core.review.ReviewManagerFactory

class AppManagementService(private val appContext: Context) {

    private val TAG = "AppManagementService"

    private val reviewManager = ReviewManagerFactory.create(appContext)
    private val appUpdateManager = AppUpdateManagerFactory.create(appContext)
    private var installStateListener: InstallStateUpdatedListener? = null

    // ------------------------------------
    // In-App Review
    // ------------------------------------

    fun requestInAppReview(activity: Activity, onResult: (Boolean) -> Unit) {
        val request = reviewManager.requestReviewFlow()
        request.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val reviewInfo = task.result
                val flow = reviewManager.launchReviewFlow(activity, reviewInfo)
                flow.addOnCompleteListener {
                    // The review flow has finished. The API does not indicate
                    // whether the user reviewed or not, or even whether the
                    // review dialog was shown.
                    onResult(true)
                }
            } else {
                Log.w(TAG, "Failed to request review flow: ${task.exception?.message}")
                onResult(false)
            }
        }
    }

    // ------------------------------------
    // In-App Updates
    // ------------------------------------

    fun checkForUpdate(onResult: (String) -> Unit) {
        val appUpdateInfoTask = appUpdateManager.appUpdateInfo
        appUpdateInfoTask.addOnSuccessListener { appUpdateInfo ->
            val isAvailable = appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
            val isImmediateAllowed = isAvailable &&
                appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
            val isFlexibleAllowed = isAvailable &&
                appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
            val versionCode = if (isAvailable) appUpdateInfo.availableVersionCode() else 0
            val stalenessDays = appUpdateInfo.clientVersionStalenessDays() ?: -1

            val json = """
                {
                    "IsUpdateAvailable": $isAvailable,
                    "IsImmediateAllowed": $isImmediateAllowed,
                    "IsFlexibleAllowed": $isFlexibleAllowed,
                    "AvailableVersionCode": $versionCode,
                    "StalenessDays": $stalenessDays
                }
            """.trimIndent()

            onResult(json)
        }
        appUpdateInfoTask.addOnFailureListener { e ->
            Log.w(TAG, "Failed to check for update: ${e.message}")
            onResult("{\"IsUpdateAvailable\":false}")
        }
    }

    fun startImmediateUpdate(activity: Activity, onResult: (Int) -> Unit) {
        val appUpdateInfoTask = appUpdateManager.appUpdateInfo
        appUpdateInfoTask.addOnSuccessListener { appUpdateInfo ->
            if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
            ) {
                try {
                    appUpdateManager.startUpdateFlowForResult(
                        appUpdateInfo,
                        activity,
                        AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build(),
                        REQUEST_CODE_IMMEDIATE_UPDATE
                    )
                    // Result will come through onActivityResult.
                    // For simplicity, we report success here since the flow was launched.
                    onResult(RESULT_SUCCESS)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start immediate update: ${e.message}")
                    onResult(RESULT_FAILED)
                }
            } else {
                Log.w(TAG, "Immediate update not available")
                onResult(RESULT_NOT_AVAILABLE)
            }
        }
        appUpdateInfoTask.addOnFailureListener { e ->
            Log.e(TAG, "Failed to get update info for immediate update: ${e.message}")
            onResult(RESULT_FAILED)
        }
    }

    fun startFlexibleUpdate(activity: Activity, onProgress: (Float) -> Unit, onResult: (Int) -> Unit) {
        val appUpdateInfoTask = appUpdateManager.appUpdateInfo
        appUpdateInfoTask.addOnSuccessListener { appUpdateInfo ->
            if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
            ) {
                // Unregister any previous listener
                unregisterListener()

                installStateListener = InstallStateUpdatedListener { state ->
                    when (state.installStatus()) {
                        InstallStatus.DOWNLOADING -> {
                            val bytesDownloaded = state.bytesDownloaded()
                            val totalBytesToDownload = state.totalBytesToDownload()
                            if (totalBytesToDownload > 0) {
                                val progress = bytesDownloaded.toFloat() / totalBytesToDownload.toFloat()
                                onProgress(progress)
                            }
                        }
                        InstallStatus.DOWNLOADED -> {
                            onProgress(1.0f)
                            onResult(RESULT_SUCCESS)
                            unregisterListener()
                        }
                        InstallStatus.FAILED -> {
                            onResult(RESULT_FAILED)
                            unregisterListener()
                        }
                        InstallStatus.CANCELED -> {
                            onResult(RESULT_USER_CANCELLED)
                            unregisterListener()
                        }
                        else -> {
                            // PENDING, INSTALLING, INSTALLED, UNKNOWN — no action needed
                        }
                    }
                }

                appUpdateManager.registerListener(installStateListener!!)

                try {
                    // For flexible updates we don't need an Activity result,
                    // but startUpdateFlowForResult still requires one.
                    // We use appContext cast — if it fails, the caller should
                    // provide an Activity context.
                    appUpdateManager.startUpdateFlowForResult(
                        appUpdateInfo,
                        activity,
                        AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build(),
                        REQUEST_CODE_FLEXIBLE_UPDATE
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start flexible update: ${e.message}")
                    onResult(RESULT_FAILED)
                    unregisterListener()
                }
            } else {
                Log.w(TAG, "Flexible update not available")
                onResult(RESULT_NOT_AVAILABLE)
            }
        }
        appUpdateInfoTask.addOnFailureListener { e ->
            Log.e(TAG, "Failed to get update info for flexible update: ${e.message}")
            onResult(RESULT_FAILED)
        }
    }

    fun completeUpdate() {
        appUpdateManager.completeUpdate()
    }

    private fun unregisterListener() {
        installStateListener?.let {
            appUpdateManager.unregisterListener(it)
            installStateListener = null
        }
    }

    companion object {
        const val REQUEST_CODE_IMMEDIATE_UPDATE = 1002

        const val RESULT_SUCCESS = 0
        const val RESULT_USER_CANCELLED = 1
        const val RESULT_FAILED = 2
        const val RESULT_NOT_AVAILABLE = 3
        const val REQUEST_CODE_FLEXIBLE_UPDATE = 1003
    }
}
