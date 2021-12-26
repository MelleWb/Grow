//
//  IAPManager.swift
//  Grow
//
//  Created by Swen Rolink on 15/12/2021.
//

import Foundation
import StoreKit

private let productIdentifiers: Set<String> = [
  "Grow.IAP.PemiumAddFree"
]


final class ProductsDB: ObservableObject, Identifiable {
  
  static let shared = ProductsDB()
  var items: [SKProduct] = [] {
      willSet {
        DispatchQueue.main.async {
          self.objectWillChange.send()
        }
      }
  }
    
    @Published var hasPurchasedProducts: Bool = false
}

class IAPManager: NSObject {
  static let shared = IAPManager()
  
  private override init() {
    super.init()
  }
  
  func getProducts() {
    let request = SKProductsRequest(productIdentifiers: productIdentifiers)
    request.delegate = self
    request.start()
  }
    
    func restoreProducts() {
        print("Restoring products ...")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
  
  func purchase(product: SKProduct) -> Bool {
    if !IAPManager.shared.canMakePayments() {
        return false
    } else {
      let payment = SKPayment(product: product)
      SKPaymentQueue.default().add(payment)
    }
    return true
  }

  func canMakePayments() -> Bool {
    return SKPaymentQueue.canMakePayments()
  }
  
  func verifyReceipt() {
    let verifyURL = "https://sandbox.itunes.apple.com/verifyReceipt"
    
    guard let receiptURL = Bundle.main.appStoreReceiptURL,
            let receiptString = try? Data(contentsOf: receiptURL).base64EncodedString() ,
            let url = URL(string: verifyURL) else {
          return
        }
                
    print("receiptURL ",receiptString)
    
    let requestData : [String : Any] = ["receipt-data" : receiptString,
                                            "password" : "214c835c2aca4b6d966704296bf25591",
                                            "exclude-old-transactions" : false]
    let httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])
        
    var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        URLSession.shared.dataTask(with: request)  { (data, response, error) in
          // convert data to Dictionary and view purchases
          DispatchQueue.main.async {
            if let data = data, let jsonData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments){
              print("jsonX ",jsonData)
              // your non-consumable and non-renewing subscription receipts are in `in_app` array
              // your auto-renewable subscription receipts are in `latest_receipt_info` array
            }
          }
        }.resume()
  }
}

extension IAPManager: SKProductsRequestDelegate, SKRequestDelegate {

  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    let badProducts = response.invalidProductIdentifiers
    let goodProducts = response.products
    
    if !goodProducts.isEmpty {
      ProductsDB.shared.items = response.products
      print("bon ", ProductsDB.shared.items)
    }
    
    print("badProducts ", badProducts)
  }
  
  func request(_ request: SKRequest, didFailWithError error: Error) {
    print("didFailWithError ", error)
    DispatchQueue.main.async {
      print("purchase failed")
    }
  }
  
  func requestDidFinish(_ request: SKRequest) {
    DispatchQueue.main.async {
      print("request did finish ")
    }
  }
  
  func completeTransaction(_ transaction: SKPaymentTransaction) {
    print("transaction ",transaction)

  }
  
  func startObserving() {
    SKPaymentQueue.default().add(self)
  }
 
  func stopObserving() {
    SKPaymentQueue.default().remove(self)
  }
  
}


extension IAPManager: SKPaymentTransactionObserver {
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
     transactions.forEach { (transaction) in
      switch transaction.transactionState {
      case .purchased:
        SKPaymentQueue.default().finishTransaction(transaction)
        print("trans ",transaction)
        verifyReceipt()
//        verifyPurchaseWithPayment()
//        purchasePublisher.send(("Purchased ", true))
      case .restored:
          ProductsDB.shared.hasPurchasedProducts = true
          SKPaymentQueue.default().finishTransaction(transaction)
          verifyReceipt()
          //purchasePublisher.send(("Restored ", true))
      case .failed:
        if let error = transaction.error as? SKError {
//          purchasePublisher.send(("Payment Error \(error.code) ", false))
          print("Payment Failed \(error.code)")
        }
        SKPaymentQueue.default().finishTransaction(transaction)
      case .deferred:
        print("Ask Mom ...")
//        purchasePublisher.send(("Payment Diferred ", false))
      case .purchasing:
        print("working on it...")
//        purchasePublisher.send(("Payment in Process ", false))
      default:
        break
      }
    }
  }
}
