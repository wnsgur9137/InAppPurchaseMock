//
//  PurchaseManager.swift
//  AllensLibrary
//
//  Created by JunHyeok Lee on 2023/04/26.
//

import Foundation
import StoreKit

public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

final class IAPHelper: NSObject {
    private let productIdentifiers: Set<String>
    private var purchasedProductIDList: Set<String> = []
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?

    public init(productIDs: Set<String>) {
        productIdentifiers = productIDs
        purchasedProductIDList = productIDs.filter { UserDefaults.shared.bool(forKey: $0) == true }
        super.init()
        SKPaymentQueue.default().add(self)
    }

    func loadsRequest(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPHelper: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        productsRequestCompletionHandler?(true, products)
        clearRequest()
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        productsRequestCompletionHandler?(false, nil)
        clearRequest()
    }

    private func clearRequest() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

// MARK: - 구매 이력
extension IAPHelper {
    func getReceiptData() -> String? {
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                let receiptString = receiptData.base64EncodedString(options: [])
                return receiptString
            } catch {
                print("Couldn't read receipt data with error: \(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }

    func restorePurchases() {
        for productID in productIdentifiers {
            UserDefaults.shared.set(false, productID)
        }
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - 구매
extension IAPHelper {
    func buyProduct(_ product: SKProduct) {
        SystemManager.shared.openLoading()
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    func isProductPurchased(_ productID: String) -> Bool {
        return self.purchasedProductIDList.contains(productID)
    }
}

// MARK: - SKPaymentTransactionObserver
extension IAPHelper: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            let state = transaction.transactionState
            switch state {
            case .purchased:
                complete(transaction: transaction)
            case .failed:
                fail(transaction: transaction)
            case .restored:
                restore(transaction: transaction)
            case .deferred, .purchasing:
                break
            default:
                SystemManager.shared.closeLoading()
            }
        }
    }

    private func complete(transaction: SKPaymentTransaction) {
        deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        purchasedProductIDList.insert(productIdentifier)
        UserDefaults.shared.setValue(true, forKey: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func fail(transaction: SKPaymentTransaction) {
        if let transactionError = transaction.error as NSError?,
           let localizedDescription = transaction.error?.localizedDescription,
           transactionError.code != SKError.paymentCancelled.rawValue {
            print("Transaction Error: \(localizedDescription)")
        }
        deliverPurchaseNotificationFor(identifier: nil)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func deliverPurchaseNotificationFor(identifier: String?) {
        if let identifier = identifier {
            purchasedProductIDList.insert(identifier)
            UserDefaults.shared.setValue(true, forKey: identifier)
            NotificationCenter.default.post(name: .IAPServicePurchaseNotification, object: (true, identifier))
        } else {
            NotificationCenter.default.post(name: .IAPServicePurchaseNotification, object: (false, ""))
        }
        SystemManager.shared.closeLoading()
    }

    private func addNoti() {
        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseNoti(_:), name: .IAPServicePurchaseNotification), object: nil)
    }

    @objc private func handlePurchaseNoti(_ notification: Notification) {
        guard let result = notification.object as? (Bool, String) else { return }
        let isSuccess = result.0
        if isSuccess {
            switch result.1 {
            case IAPCustomTab:
            moveCustomUITab:
            }
        }
    }
}
