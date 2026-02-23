import Foundation
@testable import NoctuaSDK

class MockFirebaseQueryService: FirebaseQueryServiceProtocol {
    var installationIdToReturn = "mock-installation-id"
    var sessionIdToReturn = "mock-session-id"
    var remoteConfigStrings: [String: String] = [:]
    var remoteConfigBooleans: [String: Bool] = [:]
    var remoteConfigDoubles: [String: Double] = [:]
    var remoteConfigLongs: [String: Int64] = [:]
    var fetchRemoteConfigCalled = false

    func getFirebaseInstallationID(completion: @escaping (String) -> Void) {
        completion(installationIdToReturn)
    }

    func getFirebaseSessionID(completion: @escaping (String) -> Void) {
        completion(sessionIdToReturn)
    }

    func fetchRemoteConfig() {
        fetchRemoteConfigCalled = true
    }

    func getFirebaseRemoteConfigString(key: String) -> String {
        return remoteConfigStrings[key] ?? ""
    }

    func getFirebaseRemoteConfigBoolean(key: String) -> Bool {
        return remoteConfigBooleans[key] ?? false
    }

    func getFirebaseRemoteConfigDouble(key: String) -> Double {
        return remoteConfigDoubles[key] ?? 0.0
    }

    func getFirebaseRemoteConfigLong(key: String) -> Int64 {
        return remoteConfigLongs[key] ?? 0
    }
}
