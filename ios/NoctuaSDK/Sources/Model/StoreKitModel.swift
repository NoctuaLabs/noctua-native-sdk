import Foundation

// MARK: - Enums

@objc public enum StoreKitErrorCode: Int {
    case ok = 0
    case userCanceled = 1
    case serviceUnavailable = 2
    case storeKitUnavailable = 3
    case itemUnavailable = 4
    case developerError = 5
    case error = 6
    case itemAlreadyOwned = 7
    case itemNotOwned = 8
    case networkError = 12
    case serviceDisconnected = -1
    case featureNotSupported = -2
}

@objc public enum PurchaseState: Int {
    case unspecified = 0
    case purchased = 1
    case pending = 2
}

@objc public enum ProductType: Int {
    case inapp = 0
    case subs = 1
}

@objc public enum ConsumableType: Int {
    case consumable = 0
    case nonConsumable = 1
    case subscription = 2
}

// MARK: - Product Details

@objc public class NoctuaProductDetails: NSObject {
    @objc public let productId: String
    @objc public let title: String
    @objc public let productDescription: String
    @objc public let formattedPrice: String
    @objc public let priceAmountMicros: Int64
    @objc public let priceCurrencyCode: String
    @objc public let productType: ProductType
    @objc public let subscriptionOfferDetails: [NoctuaSubscriptionOfferDetails]?

    @objc public init(
        productId: String,
        title: String,
        productDescription: String,
        formattedPrice: String,
        priceAmountMicros: Int64,
        priceCurrencyCode: String,
        productType: ProductType,
        subscriptionOfferDetails: [NoctuaSubscriptionOfferDetails]? = nil
    ) {
        self.productId = productId
        self.title = title
        self.productDescription = productDescription
        self.formattedPrice = formattedPrice
        self.priceAmountMicros = priceAmountMicros
        self.priceCurrencyCode = priceCurrencyCode
        self.productType = productType
        self.subscriptionOfferDetails = subscriptionOfferDetails
        super.init()
    }
}

// MARK: - Subscription Offer Details

@objc public class NoctuaSubscriptionOfferDetails: NSObject {
    @objc public let basePlanId: String
    @objc public let offerId: String?
    @objc public let offerToken: String
    @objc public let pricingPhases: [NoctuaPricingPhase]

    @objc public init(
        basePlanId: String,
        offerId: String?,
        offerToken: String,
        pricingPhases: [NoctuaPricingPhase]
    ) {
        self.basePlanId = basePlanId
        self.offerId = offerId
        self.offerToken = offerToken
        self.pricingPhases = pricingPhases
        super.init()
    }
}

// MARK: - Pricing Phase

@objc public class NoctuaPricingPhase: NSObject {
    @objc public let formattedPrice: String
    @objc public let priceAmountMicros: Int64
    @objc public let priceCurrencyCode: String
    @objc public let billingPeriod: String
    @objc public let recurrenceMode: Int

    @objc public init(
        formattedPrice: String,
        priceAmountMicros: Int64,
        priceCurrencyCode: String,
        billingPeriod: String,
        recurrenceMode: Int
    ) {
        self.formattedPrice = formattedPrice
        self.priceAmountMicros = priceAmountMicros
        self.priceCurrencyCode = priceCurrencyCode
        self.billingPeriod = billingPeriod
        self.recurrenceMode = recurrenceMode
        super.init()
    }
}

// MARK: - Purchase Result

@objc public class NoctuaPurchaseResult: NSObject {
    @objc public let success: Bool
    @objc public let errorCode: StoreKitErrorCode
    @objc public let purchaseState: PurchaseState
    @objc public let productId: String
    @objc public let orderId: String?
    @objc public let purchaseToken: String
    @objc public let purchaseTime: Int64
    @objc public let isAcknowledged: Bool
    @objc public let isAutoRenewing: Bool
    @objc public let quantity: Int
    @objc public let message: String
    @objc public let originalJson: String

    @objc public init(
        success: Bool,
        errorCode: StoreKitErrorCode = .ok,
        purchaseState: PurchaseState = .unspecified,
        productId: String = "",
        orderId: String? = nil,
        purchaseToken: String = "",
        purchaseTime: Int64 = 0,
        isAcknowledged: Bool = false,
        isAutoRenewing: Bool = false,
        quantity: Int = 1,
        message: String = "",
        originalJson: String = ""
    ) {
        self.success = success
        self.errorCode = errorCode
        self.purchaseState = purchaseState
        self.productId = productId
        self.orderId = orderId
        self.purchaseToken = purchaseToken
        self.purchaseTime = purchaseTime
        self.isAcknowledged = isAcknowledged
        self.isAutoRenewing = isAutoRenewing
        self.quantity = quantity
        self.message = message
        self.originalJson = originalJson
        super.init()
    }

    @objc public func isPending() -> Bool {
        return purchaseState == .pending
    }

    @objc public func isPurchased() -> Bool {
        return purchaseState == .purchased
    }
}

// MARK: - Product Purchase Status

@objc public class NoctuaProductPurchaseStatus: NSObject {
    @objc public let productId: String
    @objc public let isPurchased: Bool
    @objc public let isAcknowledged: Bool
    @objc public let isAutoRenewing: Bool
    @objc public let purchaseState: PurchaseState
    @objc public let purchaseToken: String
    @objc public let purchaseTime: Int64
    @objc public let orderId: String?
    @objc public let originalJson: String

    @objc public init(
        productId: String,
        isPurchased: Bool,
        isAcknowledged: Bool = false,
        isAutoRenewing: Bool = false,
        purchaseState: PurchaseState = .unspecified,
        purchaseToken: String = "",
        purchaseTime: Int64 = 0,
        orderId: String? = nil,
        originalJson: String = ""
    ) {
        self.productId = productId
        self.isPurchased = isPurchased
        self.isAcknowledged = isAcknowledged
        self.isAutoRenewing = isAutoRenewing
        self.purchaseState = purchaseState
        self.purchaseToken = purchaseToken
        self.purchaseTime = purchaseTime
        self.orderId = orderId
        self.originalJson = originalJson
        super.init()
    }
}

// MARK: - StoreKit Config

@objc public class NoctuaStoreKitConfig: NSObject {
    @objc public let verifyPurchasesOnServer: Bool

    @objc public init(verifyPurchasesOnServer: Bool = false) {
        self.verifyPurchasesOnServer = verifyPurchasesOnServer
        super.init()
    }
}
