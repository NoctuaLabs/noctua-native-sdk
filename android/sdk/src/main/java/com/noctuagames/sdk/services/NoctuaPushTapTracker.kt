package com.noctuagames.sdk.services

import android.app.Activity
import android.app.Application
import android.os.Bundle

/**
 * Detects notification taps and dispatches them through [NoctuaPushBridge.dispatchTapped].
 *
 * A tap launches (cold start) or re-delivers (`onNewIntent`) the launcher activity with the push
 * data as intent extras. `onActivityResumed` always runs after `onNewIntent`, so checking the
 * intent there catches taps in every app state — including a tap from the shade while the app is
 * already in the foreground, where hosts like Unity raise no pause/resume callback of their own.
 */
object NoctuaPushTapTracker : Application.ActivityLifecycleCallbacks {
    private var registeredApplication: Application? = null

    /** Registers once per application, and checks [activity]'s intent for a cold-start tap. */
    fun register(activity: Activity) {
        synchronized(this) {
            val application = activity.application
            if (registeredApplication !== application) {
                registeredApplication?.unregisterActivityLifecycleCallbacks(this)
                application.registerActivityLifecycleCallbacks(this)
                registeredApplication = application
            }
        }
        check(activity)
    }

    private fun check(activity: Activity) {
        NoctuaPushBridge.consumeTapIntent(activity.intent)?.let(NoctuaPushBridge::dispatchTapped)
    }

    override fun onActivityResumed(activity: Activity) = check(activity)

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityPaused(activity: Activity) {}
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onActivityDestroyed(activity: Activity) {}
}
