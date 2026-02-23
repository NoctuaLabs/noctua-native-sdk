import Foundation
@testable import NoctuaSDK

class MockStoreKitService: StoreKitServiceProtocol {
    var initializeCalled = false
    var initializeListener: StoreKitEventListener?
    var disposeCalled = false
    var isReadyReturnValue = false
    var registeredProducts: [(String, ConsumableType)] = []
    var queryProductDetailsCalls: [([String], ProductType)] = []
    var purchaseCalls: [String] = []
    var queryPurchasesCalls: [ProductType] = []
    var restorePurchasesCalled = false
    var getProductPurchaseStatusCalls: [String] = []
    var completePurchaseProcessingCalls: [(String, ConsumableType, Bool)] = []
    var completePurchaseProcessingResult = true

    func initialize(listener: StoreKitEventListener?) {
        initializeCalled = true
        initializeListener = listener
    }

    func dispose() {
        disposeCalled = true
    }

    func isReady() -> Bool {
        return isReadyReturnValue
    }

    func registerProduct(productId: String, consumableType: ConsumableType) {
        registeredProducts.append((productId, consumableType))
    }

    func queryProductDetails(productIds: [String], productType: ProductType) {
        queryProductDetailsCalls.append((productIds, productType))
    }

    func purchase(productId: String) {
        purchaseCalls.append(productId)
    }

    func queryPurchases(productType: ProductType) {
        queryPurchasesCalls.append(productType)
    }

    func restorePurchases() {
        restorePurchasesCalled = true
    }

    func getProductPurchaseStatus(productId: String) {
        getProductPurchaseStatusCalls.append(productId)
    }

    func completePurchaseProcessing(purchaseToken: String, consumableType: ConsumableType, verified: Bool, callback: ((Bool) -> Void)?) {
        completePurchaseProcessingCalls.append((purchaseToken, consumableType, verified))
        callback?(completePurchaseProcessingResult)
    }
}
