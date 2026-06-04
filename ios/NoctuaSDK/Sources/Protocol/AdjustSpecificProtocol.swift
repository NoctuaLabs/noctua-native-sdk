import Foundation

protocol AdjustSpecificProtocol {
    func onOnline()
    func onOffline()
    func getAdjustCurrentAttribution(completion: @escaping ([String: Any]) -> Void)
    func getAdjustAdid(completion: @escaping (String?) -> Void)
    func getAdjustIdfa(completion: @escaping (String?) -> Void)
    func getAdjustIdfv(completion: @escaping (String?) -> Void)
    func getAdjustSdkVersion(completion: @escaping (String?) -> Void)
}
