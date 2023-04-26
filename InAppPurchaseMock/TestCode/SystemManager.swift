//
//  SystemManager.swift
//  AllensLibrary
//
//  Created by JunHyeok Lee on 2023/04/26.
//

import Foundation

final class SystemManager {
    static let shared = SystemManager()
    private init() {
        iAPManager = IAPHelper(productIDs: set<String>([IAPCustomTab, IAPAdMob, IAPPremium]))
    }

    private var iAPManager: IAPHelper
}

// MARK: - IAP
extension SystemManager {
    func initIAP() {
        iAPManager.loadsRequest({ [weak self] success, products in
            if success {
                guard let products = products else { return }
                productList = products
                iAPManager.restorePurchases()
            } else {
                print("iAPManager.loadsRequest Error")
            }
        })
    }

    func isProductPurchased(_ productID: String) -> Bool {
        return iAPManager.isProductPurchased(productID)
    }

    func buyProduct(_ productID: String) {
        openLoading()
        for product in productList {
            if product.productIdentifier == productID {
                iAPManager.buyProduct(product)
                break
            }
        }
    }
}

