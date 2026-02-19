import Foundation

protocol FirebaseQueryServiceProtocol {
    func getFirebaseInstallationID(completion: @escaping (String) -> Void)
    func getFirebaseSessionID(completion: @escaping (String) -> Void)
    func fetchRemoteConfig()
    func getFirebaseRemoteConfigString(key: String) -> String
    func getFirebaseRemoteConfigBoolean(key: String) -> Bool
    func getFirebaseRemoteConfigDouble(key: String) -> Double
    func getFirebaseRemoteConfigLong(key: String) -> Int64
}
