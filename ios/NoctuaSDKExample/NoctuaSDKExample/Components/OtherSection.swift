import SwiftUI
import os
import NoctuaSDK

struct OtherSection: View {
    let logger: Logger

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                fatalError("Crash was triggered")
            }) {
                actionButtonLabel("Crash Me", color: .red)
            }

            Button(action: {
                let welcomeMessage = Noctua.getFirebaseRemoteConfigString(key: "welcome_message")
                logger.debug("Firebase Remote Config value: \(welcomeMessage ?? "")")
            }) {
                actionButtonLabel("Get Firebase Remote Config")
            }
        }
    }
}
