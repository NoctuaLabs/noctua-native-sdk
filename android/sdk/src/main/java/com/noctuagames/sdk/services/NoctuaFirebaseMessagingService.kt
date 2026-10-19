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
        val notification = remoteMessage.notification
        notification?.let {
            NoctuaLog.d(TAG, "Message Notification Body: ${it.body}")
        }

        val json = NoctuaPushBridge.buildPayloadJson(
            messageId = remoteMessage.messageId,
            title = notification?.title,
            body = notification?.body,
            data = remoteMessage.data,
        )
        NoctuaPushBridge.dispatchReceived(json)

        // FCM only displays notification messages itself while the app is in the background.
        if (notification != null) {
            NoctuaNotificationDisplayer.show(
                context = this,
                messageId = remoteMessage.messageId,
                title = notification.title,
                body = notification.body,
                channelId = notification.channelId,
                data = remoteMessage.data,
            )
        }
    }
}
