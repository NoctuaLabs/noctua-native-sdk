import Foundation
import StoreKit
@testable import NoctuaSDK

class MockPaymentQueue: PaymentQueueProtocol {
    var addObserverCalled = false
    var addedObservers: [SKPaymentTransactionObserver] = []
    var removeObserverCalled = false
    var removedObservers: [SKPaymentTransactionObserver] = []
    var addedPayments: [SKPayment] = []
    var restoreCompletedTransactionsCalled = false
    var finishedTransactions: [SKPaymentTransaction] = []

    func add(_ observer: SKPaymentTransactionObserver) {
        addObserverCalled = true
        addedObservers.append(observer)
    }

    func remove(_ observer: SKPaymentTransactionObserver) {
        removeObserverCalled = true
        removedObservers.append(observer)
    }

    func add(_ payment: SKPayment) {
        addedPayments.append(payment)
    }

    func restoreCompletedTransactions() {
        restoreCompletedTransactionsCalled = true
    }

    func finishTransaction(_ transaction: SKPaymentTransaction) {
        finishedTransactions.append(transaction)
    }
}
