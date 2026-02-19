import Foundation

protocol AdjustSpecificProtocol {
    func onOnline()
    func onOffline()
    func getAdjustCurrentAttribution(completion: @escaping ([String: Any]) -> Void)
}
