import SwiftUI
import NoctuaSDK
import os
import FirebaseCore
import FirebaseMessaging

@main
struct NoctuaSDKExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let gameId: Int64
    
    init() {
        try! Noctua.initNoctua()
        
        gameId = (Bundle.main.bundleIdentifier?.contains("unity") ?? false) ? 1 : 2
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(gameId: gameId)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                os_log("Failed to request notification authorization: %{public}@", error.localizedDescription)
            } else {
                os_log("Notification authorization granted: %{public}@", String(granted))
            }
        }
        
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // MARK: Messaging Delegate Methods
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        os_log("Firebase registration token: %{public}@", fcmToken ?? "None")
        
        // Notify the SDK or backend with the new FCM token if needed
        if let token = fcmToken {
            // Example: Noctua.setFCMToken(token)
            os_log("FCM Token updated in Noctua SDK.")
        }
    }
}
