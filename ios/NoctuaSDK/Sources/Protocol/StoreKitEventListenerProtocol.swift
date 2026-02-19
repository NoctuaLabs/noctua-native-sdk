import Foundation

protocol StoreKitEventListener: AnyObject {
    func onPurchaseCompleted(result: NoctuaPurchaseResult)
    func onPurchaseUpdated(result: NoctuaPurchaseResult)
    func onProductDetailsLoaded(products: [NoctuaProductDetails])
    func onQueryPurchasesCompleted(purchases: [NoctuaPurchaseResult])
    func onRestorePurchasesCompleted(purchases: [NoctuaPurchaseResult])
    func onProductPurchaseStatusResult(status: NoctuaProductPurchaseStatus)
    func onServerVerificationRequired(result: NoctuaPurchaseResult, consumableType: ConsumableType)
    func onStoreKitError(error: StoreKitErrorCode, message: String)
}
