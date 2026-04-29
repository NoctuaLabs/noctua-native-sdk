package com.noctuagames.sdk.inspector

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import com.google.firebase.FirebaseApp
import com.noctuagames.sdk.utils.NoctuaLog

/**
 * Read-only build / config metadata for the Inspector "Build" sanity
 * panel. All getters return safe defaults ("" / 0 / -1) when the
 * underlying API isn't available.
 *
 * Sandbox-only contract: callers must already have verified
 * [NoctuaInspectorBus.isEnabled] before invoking.
 */
object BuildInfoProvider {

    private const val TAG = "NoctuaBuildInfo"

    /** SDK semver. Bumped in lockstep with `android/version.txt`. */
    const val NATIVE_SDK_VERSION: String = "0.32.0"

    /**
     * Returns the Firebase project ID associated with this build.
     * Reads `FirebaseApp.getInstance().options.projectId` — populated
     * at build time from `google-services.json` by the google-services
     * Gradle plugin. Returns "" when Firebase isn't initialized or no
     * project ID was provided.
     */
    @JvmStatic
    fun firebaseProjectId(): String {
        return try {
            FirebaseApp.getInstance().options.projectId ?: ""
        } catch (t: Throwable) {
            NoctuaLog.w(TAG, "FirebaseApp.options not available: ${t.message}")
            ""
        }
    }

    /**
     * Counts the manifest-declared permissions (uses-permission) for
     * the running package. -1 on lookup failure so the Inspector can
     * distinguish "no permissions declared" (0) from "couldn't read".
     */
    @JvmStatic
    fun permissionsCount(context: Context?): Int {
        if (context == null) return -1
        return try {
            val pm = context.packageManager
            val pkg: PackageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getPackageInfo(
                    context.packageName,
                    PackageManager.PackageInfoFlags.of(PackageManager.GET_PERMISSIONS.toLong())
                )
            } else {
                @Suppress("DEPRECATION")
                pm.getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)
            }
            pkg.requestedPermissions?.size ?: 0
        } catch (t: Throwable) {
            NoctuaLog.w(TAG, "permissionsCount lookup failed: ${t.message}")
            -1
        }
    }
}
