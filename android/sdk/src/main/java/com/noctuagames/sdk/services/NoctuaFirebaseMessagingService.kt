package com.noctuagames.sdk.services

import com.noctuagames.sdk.utils.NoctuaLog
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class NoctuaFirebaseMessagingService : FirebaseMessagingService() {
    private val TAG = this::class.simpleName

    override fun onNewToken(token: String) {
        NoctuaLog.d(TAG, "Refreshed token")
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        remoteMessage.notification?.let {
            // Handle received notification
            NoctuaLog.d(TAG, "Message Notification Body: ${it.body}")
        }
    }
}