import Foundation

protocol IAPServiceProtocol {
    func purchaseItem(productId: String, completion: @escaping CompletionCallback)
    func getProductPurchasedById(id productId: String, completion: @escaping (Bool) -> Void) async
    func getReceiptProductPurchasedStoreKit1(id productId: String, completion: @escaping (String) -> Void)
    func getActiveCurrency(productId: String, completion: @escaping CompletionCallback)
}
