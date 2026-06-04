import Foundation
@testable import NoctuaSDK

class MockAdjustSpecific: AdjustSpecificProtocol {
    var onOnlineCalled = false
    var onOfflineCalled = false
    var attributionToReturn: [String: Any] = [:]
    var getAttributionCallCount = 0

    var adidToReturn: String? = "mock-adid"
    var idfaToReturn: String? = "mock-idfa"
    var idfvToReturn: String? = "mock-idfv"
    var sdkVersionToReturn: String? = "mock-sdk-version"

    var getAdidCallCount = 0
    var getIdfaCallCount = 0
    var getIdfvCallCount = 0
    var getSdkVersionCallCount = 0

    func onOnline() {
        onOnlineCalled = true
    }

    func onOffline() {
        onOfflineCalled = true
    }

    func getAdjustCurrentAttribution(completion: @escaping ([String: Any]) -> Void) {
        getAttributionCallCount += 1
        completion(attributionToReturn)
    }

    func getAdjustAdid(completion: @escaping (String?) -> Void) {
        getAdidCallCount += 1
        completion(adidToReturn)
    }

    func getAdjustIdfa(completion: @escaping (String?) -> Void) {
        getIdfaCallCount += 1
        completion(idfaToReturn)
    }

    func getAdjustIdfv(completion: @escaping (String?) -> Void) {
        getIdfvCallCount += 1
        completion(idfvToReturn)
    }

    func getAdjustSdkVersion(completion: @escaping (String?) -> Void) {
        getSdkVersionCallCount += 1
        completion(sdkVersionToReturn)
    }
}
