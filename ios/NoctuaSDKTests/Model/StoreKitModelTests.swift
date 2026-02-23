import XCTest
@testable import NoctuaSDK

class StoreKitModelTests: XCTestCase {

    // MARK: - Enum Raw Values

    func testStoreKitErrorCodeRawValues() {
        XCTAssertEqual(StoreKitErrorCode.ok.rawValue, 0)
        XCTAssertEqual(StoreKitErrorCode.userCanceled.rawValue, 1)
        XCTAssertEqual(StoreKitErrorCode.serviceUnavailable.rawValue, 2)
        XCTAssertEqual(StoreKitErrorCode.storeKitUnavailable.rawValue, 3)
        XCTAssertEqual(StoreKitErrorCode.itemUnavailable.rawValue, 4)
        XCTAssertEqual(StoreKitErrorCode.developerError.rawValue, 5)
        XCTAssertEqual(StoreKitErrorCode.error.rawValue, 6)
        XCTAssertEqual(StoreKitErrorCode.itemAlreadyOwned.rawValue, 7)
        XCTAssertEqual(StoreKitErrorCode.itemNotOwned.rawValue, 8)
        XCTAssertEqual(StoreKitErrorCode.networkError.rawValue, 12)
        XCTAssertEqual(StoreKitErrorCode.serviceDisconnected.rawValue, -1)
        XCTAssertEqual(StoreKitErrorCode.featureNotSupported.rawValue, -2)
    }

    func testPurchaseStateRawValues() {
        XCTAssertEqual(PurchaseState.unspecified.rawValue, 0)
        XCTAssertEqual(PurchaseState.purchased.rawValue, 1)
        XCTAssertEqual(PurchaseState.pending.rawValue, 2)
    }

    func testProductTypeRawValues() {
        XCTAssertEqual(ProductType.inapp.rawValue, 0)
        XCTAssertEqual(ProductType.subs.rawValue, 1)
    }

    func testConsumableTypeRawValues() {
        XCTAssertEqual(ConsumableType.consumable.rawValue, 0)
        XCTAssertEqual(ConsumableType.nonConsumable.rawValue, 1)
        XCTAssertEqual(ConsumableType.subscription.rawValue, 2)
    }

    // MARK: - NoctuaProductDetails

    func testNoctuaProductDetailsInit() {
        let details = NoctuaProductDetails(
            productId: "com.test.product",
            title: "Test Product",
            productDescription: "A test product",
            formattedPrice: "$0.99",
            priceAmountMicros: 990000,
            priceCurrencyCode: "USD",
            productType: .inapp
        )

        XCTAssertEqual(details.productId, "com.test.product")
        XCTAssertEqual(details.title, "Test Product")
        XCTAssertEqual(details.productDescription, "A test product")
        XCTAssertEqual(details.formattedPrice, "$0.99")
        XCTAssertEqual(details.priceAmountMicros, 990000)
        XCTAssertEqual(details.priceCurrencyCode, "USD")
        XCTAssertEqual(details.productType, .inapp)
        XCTAssertNil(details.subscriptionOfferDetails)
    }

    func testNoctuaProductDetailsWithSubscriptionOffers() {
        let phase = NoctuaPricingPhase(
            formattedPrice: "$4.99",
            priceAmountMicros: 4990000,
            priceCurrencyCode: "USD",
            billingPeriod: "P1M",
            recurrenceMode: 1
        )
        let offer = NoctuaSubscriptionOfferDetails(
            basePlanId: "monthly",
            offerId: "intro-offer",
            offerToken: "token123",
            pricingPhases: [phase]
        )
        let details = NoctuaProductDetails(
            productId: "com.test.sub",
            title: "Monthly Sub",
            productDescription: "Monthly subscription",
            formattedPrice: "$4.99",
            priceAmountMicros: 4990000,
            priceCurrencyCode: "USD",
            productType: .subs,
            subscriptionOfferDetails: [offer]
        )

        XCTAssertEqual(details.productType, .subs)
        XCTAssertEqual(details.subscriptionOfferDetails?.count, 1)
        XCTAssertEqual(details.subscriptionOfferDetails?[0].basePlanId, "monthly")
        XCTAssertEqual(details.subscriptionOfferDetails?[0].offerId, "intro-offer")
        XCTAssertEqual(details.subscriptionOfferDetails?[0].pricingPhases.count, 1)
    }

    // MARK: - NoctuaPurchaseResult

    func testNoctuaPurchaseResultDefaults() {
        let result = NoctuaPurchaseResult(success: true)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.errorCode, .ok)
        XCTAssertEqual(result.purchaseState, .unspecified)
        XCTAssertEqual(result.productId, "")
        XCTAssertNil(result.orderId)
        XCTAssertEqual(result.purchaseToken, "")
        XCTAssertEqual(result.purchaseTime, 0)
        XCTAssertFalse(result.isAcknowledged)
        XCTAssertFalse(result.isAutoRenewing)
        XCTAssertEqual(result.quantity, 1)
        XCTAssertEqual(result.message, "")
        XCTAssertEqual(result.originalJson, "")
    }

    func testNoctuaPurchaseResultIsPending() {
        let pending = NoctuaPurchaseResult(success: false, purchaseState: .pending)
        XCTAssertTrue(pending.isPending())
        XCTAssertFalse(pending.isPurchased())
    }

    func testNoctuaPurchaseResultIsPurchased() {
        let purchased = NoctuaPurchaseResult(success: true, purchaseState: .purchased)
        XCTAssertTrue(purchased.isPurchased())
        XCTAssertFalse(purchased.isPending())
    }

    func testNoctuaPurchaseResultFullInit() {
        let result = NoctuaPurchaseResult(
            success: true,
            errorCode: .ok,
            purchaseState: .purchased,
            productId: "com.test.product",
            orderId: "order-123",
            purchaseToken: "token-abc",
            purchaseTime: 1700000000,
            isAcknowledged: true,
            isAutoRenewing: false,
            quantity: 2,
            message: "Purchase successful",
            originalJson: "{}"
        )

        XCTAssertEqual(result.productId, "com.test.product")
        XCTAssertEqual(result.orderId, "order-123")
        XCTAssertEqual(result.purchaseToken, "token-abc")
        XCTAssertEqual(result.purchaseTime, 1700000000)
        XCTAssertTrue(result.isAcknowledged)
        XCTAssertFalse(result.isAutoRenewing)
        XCTAssertEqual(result.quantity, 2)
        XCTAssertEqual(result.message, "Purchase successful")
    }

    // MARK: - NoctuaProductPurchaseStatus

    func testNoctuaProductPurchaseStatusInit() {
        let status = NoctuaProductPurchaseStatus(productId: "com.test.product", isPurchased: true)

        XCTAssertEqual(status.productId, "com.test.product")
        XCTAssertTrue(status.isPurchased)
        XCTAssertFalse(status.isAcknowledged)
        XCTAssertFalse(status.isAutoRenewing)
        XCTAssertEqual(status.purchaseState, .unspecified)
        XCTAssertEqual(status.purchaseToken, "")
        XCTAssertEqual(status.purchaseTime, 0)
        XCTAssertNil(status.orderId)
        XCTAssertEqual(status.originalJson, "")
    }

    func testNoctuaProductPurchaseStatusFullInit() {
        let status = NoctuaProductPurchaseStatus(
            productId: "com.test.sub",
            isPurchased: true,
            isAcknowledged: true,
            isAutoRenewing: true,
            purchaseState: .purchased,
            purchaseToken: "sub-token",
            purchaseTime: 1700000000,
            orderId: "sub-order",
            originalJson: "{\"sub\": true}"
        )

        XCTAssertEqual(status.productId, "com.test.sub")
        XCTAssertTrue(status.isAcknowledged)
        XCTAssertTrue(status.isAutoRenewing)
        XCTAssertEqual(status.purchaseState, .purchased)
        XCTAssertEqual(status.orderId, "sub-order")
    }

    // MARK: - NoctuaStoreKitConfig

    func testNoctuaStoreKitConfigDefault() {
        let config = NoctuaStoreKitConfig()
        XCTAssertFalse(config.verifyPurchasesOnServer)
    }

    func testNoctuaStoreKitConfigWithVerification() {
        let config = NoctuaStoreKitConfig(verifyPurchasesOnServer: true)
        XCTAssertTrue(config.verifyPurchasesOnServer)
    }

    // MARK: - NoctuaSubscriptionOfferDetails

    func testSubscriptionOfferDetailsInit() {
        let phase = NoctuaPricingPhase(
            formattedPrice: "$9.99",
            priceAmountMicros: 9990000,
            priceCurrencyCode: "USD",
            billingPeriod: "P1Y",
            recurrenceMode: 2
        )
        let offer = NoctuaSubscriptionOfferDetails(
            basePlanId: "yearly",
            offerId: nil,
            offerToken: "yearly-token",
            pricingPhases: [phase]
        )

        XCTAssertEqual(offer.basePlanId, "yearly")
        XCTAssertNil(offer.offerId)
        XCTAssertEqual(offer.offerToken, "yearly-token")
        XCTAssertEqual(offer.pricingPhases.count, 1)
        XCTAssertEqual(offer.pricingPhases[0].formattedPrice, "$9.99")
        XCTAssertEqual(offer.pricingPhases[0].billingPeriod, "P1Y")
        XCTAssertEqual(offer.pricingPhases[0].recurrenceMode, 2)
    }
}
