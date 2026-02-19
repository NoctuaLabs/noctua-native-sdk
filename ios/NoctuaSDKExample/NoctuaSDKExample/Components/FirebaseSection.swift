import SwiftUI
import os
import NoctuaSDK

struct FirebaseSection: View {
    let logger: Logger

    @State private var installationId: String = ""
    @State private var sessionId: String = ""
    @State private var remoteConfigKey: String = "welcome_message"
    @State private var remoteConfigResult: String = ""

    var body: some View {
        VStack(spacing: 8) {
            // Firebase IDs
            Text("Firebase IDs")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button(action: {
                    Noctua.getFirebaseInstallationID { id in
                        installationId = id
                        logger.debug("Installation ID: \(id)")
                    }
                }) {
                    actionButtonLabel("Installation ID", color: .orange)
                }

                Button(action: {
                    Noctua.getFirebaseSessionID { id in
                        sessionId = id
                        logger.debug("Session ID: \(id)")
                    }
                }) {
                    actionButtonLabel("Session ID", color: .orange)
                }
            }

            if !installationId.isEmpty {
                IdResultRow(label: "Installation ID", value: installationId)
            }

            if !sessionId.isEmpty {
                IdResultRow(label: "Session ID", value: sessionId)
            }

            // Remote Config
            Divider().padding(.vertical, 4)

            Text("Remote Config")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Config Key", text: $remoteConfigKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(size: 12))

            HStack(spacing: 8) {
                Button(action: {
                    let value = Noctua.getFirebaseRemoteConfigString(key: remoteConfigKey) ?? "nil"
                    remoteConfigResult = "String: \(value)"
                    logger.debug("Remote Config String[\(remoteConfigKey)]: \(value)")
                }) {
                    actionButtonLabel("String", color: Color(red: 0.0, green: 0.6, blue: 0.6))
                }

                Button(action: {
                    let value = Noctua.getFirebaseRemoteConfigBoolean(key: remoteConfigKey)
                    remoteConfigResult = "Boolean: \(value)"
                    logger.debug("Remote Config Bool[\(remoteConfigKey)]: \(value)")
                }) {
                    actionButtonLabel("Boolean", color: Color(red: 0.0, green: 0.6, blue: 0.6))
                }
            }

            HStack(spacing: 8) {
                Button(action: {
                    let value = Noctua.getFirebaseRemoteConfigDouble(key: remoteConfigKey)
                    remoteConfigResult = "Double: \(value)"
                    logger.debug("Remote Config Double[\(remoteConfigKey)]: \(value)")
                }) {
                    actionButtonLabel("Double", color: Color(red: 0.0, green: 0.6, blue: 0.6))
                }

                Button(action: {
                    let value = Noctua.getFirebaseRemoteConfigLong(key: remoteConfigKey)
                    remoteConfigResult = "Long: \(value)"
                    logger.debug("Remote Config Long[\(remoteConfigKey)]: \(value)")
                }) {
                    actionButtonLabel("Long", color: Color(red: 0.0, green: 0.6, blue: 0.6))
                }
            }

            if !remoteConfigResult.isEmpty {
                Text(remoteConfigResult)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color(red: 0.0, green: 0.6, blue: 0.6).opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
}

// MARK: - ID Result Row

private struct IdResultRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
}
