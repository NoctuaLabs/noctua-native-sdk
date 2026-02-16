import Foundation

class IAPPresenter {
    private let iapService: IAPServiceProtocol?
    private let logger: NoctuaLogger

    init(iapService: IAPServiceProtocol?, logger: NoctuaLogger) {
        self.iapService = iapService
        self.logger = logger
    }

    func purchaseItem(productId: String, completion: @escaping CompletionCallback) {
        logger.debug("productId: \(productId)")
        iapService?.purchaseItem(productId: productId, completion: completion)
    }

    func getProductPurchasedById(id productId: String, completion: @escaping (Bool) -> Void) async {
        await iapService?.getProductPurchasedById(id: productId, completion: completion)
    }

    func getReceiptProductPurchasedStoreKit1(id productId: String, completion: @escaping (String) -> Void) {
        iapService?.getReceiptProductPurchasedStoreKit1(id: productId, completion: completion)
    }

    func getActiveCurrency(productId: String, completion: @escaping CompletionCallback) {
        logger.debug("productId: \(productId)")
        iapService?.getActiveCurrency(productId: productId, completion: completion)
    }
}
