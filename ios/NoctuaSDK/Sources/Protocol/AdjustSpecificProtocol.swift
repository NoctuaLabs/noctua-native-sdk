import Foundation

protocol AdjustSpecificProtocol {
    func onOnline()
    func onOffline()
    func getAdjustCurrentAttribution() -> [String: Any]?
}
