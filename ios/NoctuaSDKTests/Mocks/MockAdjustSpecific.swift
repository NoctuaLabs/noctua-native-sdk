import Foundation
@testable import NoctuaSDK

class MockAdjustSpecific: AdjustSpecificProtocol {
    var onOnlineCalled = false
    var onOfflineCalled = false
    var attributionToReturn: [String: Any] = [:]
    var getAttributionCallCount = 0

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
}
