import Foundation
import StoreKit

/// A testable subclass of SKPaymentTransaction with settable properties.
/// SKPaymentTransaction's properties are read-only, so we override them.
class MockSKPaymentTransaction: SKPaymentTransaction {
    private let _payment: SKPayment
    private let _transactionState: SKPaymentTransactionState
    private let _transactionIdentifier: String?
    private let _transactionDate: Date?
    private let _error: Error?
    private let _original: SKPaymentTransaction?

    init(
        payment: SKPayment,
        transactionState: SKPaymentTransactionState,
        transactionIdentifier: String? = nil,
        transactionDate: Date? = nil,
        error: Error? = nil,
        original: SKPaymentTransaction? = nil
    ) {
        self._payment = payment
        self._transactionState = transactionState
        self._transactionIdentifier = transactionIdentifier
        self._transactionDate = transactionDate
        self._error = error
        self._original = original
        super.init()
    }

    override var payment: SKPayment { _payment }
    override var transactionState: SKPaymentTransactionState { _transactionState }
    override var transactionIdentifier: String? { _transactionIdentifier }
    override var transactionDate: Date? { _transactionDate }
    override var error: Error? { _error }
    override var original: SKPaymentTransaction? { _original }
}

/// Helper to create an SKPayment for a product ID without a real SKProduct.
/// Uses SKMutablePayment which allows setting productIdentifier.
class MockSKPayment: SKPayment {
    private let _productIdentifier: String
    private let _quantity: Int

    init(productIdentifier: String, quantity: Int = 1) {
        self._productIdentifier = productIdentifier
        self._quantity = quantity
        super.init()
    }

    override var productIdentifier: String { _productIdentifier }
    override var quantity: Int { _quantity }
}
