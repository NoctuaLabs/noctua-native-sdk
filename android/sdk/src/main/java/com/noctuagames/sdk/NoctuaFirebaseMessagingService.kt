package com.noctuagames.sdk

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class NoctuaFirebaseMessagingService : FirebaseMessagingService() {
    private val TAG = this::class.simpleName

    override fun onNewToken(token: String) {
        Log.d(TAG, "Refreshed token")
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        remoteMessage.notification?.let {
            // Handle received notification
            Log.d(TAG, "Message Notification Body: ${it.body}")
        }
    }
}