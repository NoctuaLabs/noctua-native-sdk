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
    var subscribeToTopicResult = true
    var unsubscribeFromTopicResult = true
    var fcmTokenToReturn = "mock-fcm-token"
    var deleteFcmTokenResult = true
    var subscribedTopics: [String] = []
    var unsubscribedTopics: [String] = []

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

    func subscribeToTopic(_ topic: String, completion: @escaping (Bool) -> Void) {
        subscribedTopics.append(topic)
        completion(subscribeToTopicResult)
    }

    func unsubscribeFromTopic(_ topic: String, completion: @escaping (Bool) -> Void) {
        unsubscribedTopics.append(topic)
        completion(unsubscribeFromTopicResult)
    }

    func getFcmToken(completion: @escaping (String) -> Void) {
        completion(fcmTokenToReturn)
    }

    func deleteFcmToken(completion: @escaping (Bool) -> Void) {
        completion(deleteFcmTokenResult)
    }
}
