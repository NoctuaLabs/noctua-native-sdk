import Foundation
@testable import NoctuaSDK

struct TestConfigFactory {
    static func makeConfig(
        clientId: String = "test-client-id",
        gameId: Int? = 1,
        nativeInternalTrackerEnabled: Bool? = nil,
        iapDisabled: Bool? = nil
    ) -> NoctuaConfig {
        var dict: [String: Any] = ["clientId": clientId]
        if let gameId = gameId { dict["gameId"] = gameId }

        var noctuaDict: [String: Any] = [:]
        if let enabled = nativeInternalTrackerEnabled {
            noctuaDict["nativeInternalTrackerEnabled"] = enabled
        }
        if let disabled = iapDisabled {
            noctuaDict["iapDisabled"] = disabled
        }
        if !noctuaDict.isEmpty {
            dict["noctua"] = noctuaDict
        }

        let data = try! JSONSerialization.data(withJSONObject: dict)
        return try! JSONDecoder().decode(NoctuaConfig.self, from: data)
    }
}
