import SwiftUI
import os
import NoctuaSDK

struct LifecycleSection: View {
    let logger: Logger

    @State private var isOnline: Bool = true

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button(action: {
                    Noctua.onOnline()
                    isOnline = true
                    logger.debug("Set online")
                }) {
                    actionButtonLabel("Set Online", color: .green)
                }

                Button(action: {
                    Noctua.onOffline()
                    isOnline = false
                    logger.debug("Set offline")
                }) {
                    actionButtonLabel("Set Offline", color: .red)
                }
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(isOnline ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(isOnline ? "Online" : "Offline")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
