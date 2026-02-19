import Foundation

struct NoctuaConfig: Decodable {
    let clientId: String
    let gameId: Int?
    let noctua: NoctuaServiceConfig?
    let adjust: AdjustServiceConfig?
    let firebase: FirebaseServiceConfig?
    let facebook: FacebookServiceConfig?
}

struct NoctuaServiceConfig: Decodable {
    let nativeInternalTrackerEnabled: Bool?
    let iapDisabled: Bool?
}

struct AdjustServiceConfig: Codable {
    let ios: AdjustServiceIosConfig?
}

struct AdjustServiceIosConfig: Codable {
    let appToken: String
    let environment: String?
    let customEventDisabled: Bool?
    let eventMap: [String: String]?
}

struct FirebaseServiceConfig: Codable {
    let ios: FirebaseServiceIosConfig?
}

struct FirebaseServiceIosConfig: Codable {
    let customEventDisabled: Bool?
}

struct FacebookServiceConfig: Codable {
    let ios: FacebookServiceIosConfig?
}

struct FacebookServiceIosConfig: Codable {
    let enableDebug: Bool?
    let advertiserIdCollectionEnabled: Bool?
    let autologEventsEnabled: Bool?
    let appId: String
    let clientToken: String
    let displayName: String
    let customEventDisabled: Bool?
}
