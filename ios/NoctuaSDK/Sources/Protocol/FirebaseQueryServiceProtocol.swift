import Foundation

protocol FirebaseQueryServiceProtocol {
    func getFirebaseInstallationID(completion: @escaping (String) -> Void)
    func getFirebaseSessionID(completion: @escaping (String) -> Void)
    func fetchRemoteConfig()
    func getFirebaseRemoteConfigString(key: String) -> String
    func getFirebaseRemoteConfigBoolean(key: String) -> Bool
    func getFirebaseRemoteConfigDouble(key: String) -> Double
    func getFirebaseRemoteConfigLong(key: String) -> Int64
    func subscribeToTopic(_ topic: String, completion: @escaping (Bool) -> Void)
    func unsubscribeFromTopic(_ topic: String, completion: @escaping (Bool) -> Void)
    func getFcmToken(completion: @escaping (String) -> Void)
    func deleteFcmToken(completion: @escaping (Bool) -> Void)
}
