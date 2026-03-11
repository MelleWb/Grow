//
//  StoreManager.swift
//  Grow
//
//  Created by Swen Rolink on 17/12/2021.
//

import Foundation
import StoreKit

final class StoreManager: ObservableObject {

    @Published var myProducts: [StoreKit.Product] = []
    @Published var transactionDates: [Date] = []

    private let productIDs = ["Grow.IAP.PemiumAddFree"]
    private var transactionUpdatesTask: Task<Void, Never>?

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func getProducts() {
        Task {
            await loadProducts()
        }
    }

    func purchaseProduct(product: StoreKit.Product) {
        Task {
            await purchase(product: product)
        }
    }

    func restoreProducts() {
        Task {
            do {
                try await AppStore.sync()
                await refreshEntitlements()
            } catch {
                print("Failed to restore purchases: \(error.localizedDescription)")
            }
        }
    }

    func startObserving() {
        guard transactionUpdatesTask == nil else {
            return
        }

        transactionUpdatesTask = Task(priority: .background) {
            await refreshEntitlements()

            for await result in Transaction.updates {
                await handle(transactionResult: result)
            }
        }
    }

    func stopObserving() {
        transactionUpdatesTask?.cancel()
        transactionUpdatesTask = nil
    }

    private func loadProducts() async {
        do {
            let products = try await StoreKit.Product.products(for: productIDs)
            await MainActor.run {
                myProducts = products
            }
        } catch {
            print("Failed to load products: \(error.localizedDescription)")
        }
    }

    private func purchase(product: StoreKit.Product) async {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                await handle(transactionResult: verificationResult)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error.localizedDescription)")
        }
    }

    private func refreshEntitlements() async {
        var dates: [Date] = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if let expirationDate = transaction.expirationDate {
                dates.append(expirationDate)
            } else {
                dates.append(transaction.purchaseDate)
            }
        }

        let sortedDates = dates.sorted(by: >)
        await MainActor.run {
            transactionDates = sortedDates
        }
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = transactionResult else {
            return
        }

        if let expirationDate = transaction.expirationDate {
            updateStoredDate(expirationDate, for: transaction.productID)
        } else {
            updateStoredDate(transaction.purchaseDate, for: transaction.productID)
        }

        await transaction.finish()
        await refreshEntitlements()
    }

    private func updateStoredDate(_ date: Date, for productID: String) {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: productID)
    }
}
