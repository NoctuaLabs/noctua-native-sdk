import Foundation

protocol StoreKitServiceProtocol {
    func initialize(listener: StoreKitEventListener?)
    func dispose()
    func isReady() -> Bool
    func registerProduct(productId: String, consumableType: ConsumableType)
    func queryProductDetails(productIds: [String], productType: ProductType)
    func purchase(productId: String)
    func queryPurchases(productType: ProductType)
    func restorePurchases()
    func getProductPurchaseStatus(productId: String)
    func completePurchaseProcessing(purchaseToken: String, consumableType: ConsumableType, verified: Bool, callback: ((Bool) -> Void)?)
}
