//
//  IAPService.swift
//  AllensLibrary
//
//  Created by JunHyeok Lee on 2023/04/26.
//

import StoreKit

// MARK: - Test Code

typealias ProductsRequestCompletion = (_ success: Bool, _ products: [SKProduct]?) -> Void

enum MyProducts {
    static let productID = "com.allenslibrary.study.allencash_25"
    static let iapService: IAPServiceType = IAPService(productIDs: Set<String>([productID]))
    
    static func getResourceProductName(_ id: String) -> String? {
        id.components(separatedBy: ".").last
    }
}

protocol IAPServiceType {
    var canMakePayments: Bool { get }
    
    func getProducts(completion: @escaping ProductsRequestCompletion)
    func buyProduct(_ product: SKProduct)
    func isProductPurchased(_ productID: String) -> Bool
    func restorePurchases()
}

final class IAPService: NSObject, IAPServiceType {
    private let productIDs: Set<String>
    private var purchasedProductIDs: Set<String> = []
    private var productsRequest: SKProductsRequest?
    private var productsCompletion: ProductsRequestCompletion?
    
    var canMakePayments: Bool {
        SKPaymentQueue.canMakePayments()
    }
    
    init(productIDs: Set<String>) {
        self.productIDs = productIDs
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    func getProducts(completion: @escaping ProductsRequestCompletion) {
        self.productsRequest?.cancel()
        self.productsCompletion = completion
        self.productsRequest = SKProductsRequest(productIdentifiers: self.productIDs)
        self.productsRequest?.delegate = self
        self.productsRequest?.start()
    }
}

// MARK: - SKProductsRequestDelegate
extension IAPService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        self.productsCompletion?(true, products)
        self.clearRequest()
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("SKRequest Error: \(error.localizedDescription)")
        self.productsCompletion?(false, nil)
        self.clearRequest()
    }
    
    private func clearRequest() {
        self.productsRequest = nil
        self.productsCompletion = nil
    }
    
    func buyProduct(_ product: SKProduct) {
        SKPaymentQueue.default().add(SKPayment(product: product))
    }
    
    func isProductPurchased(_ productID: String) -> Bool {
        return self.purchasedProductIDs.contains(productID)
    }
    
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}
