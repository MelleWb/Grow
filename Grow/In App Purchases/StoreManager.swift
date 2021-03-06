//
//  StoreManager.swift
//  Grow
//
//  Created by Swen Rolink on 17/12/2021.
//

import Foundation
import StoreKit
import SwiftUI

class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @Published var myProducts = [SKProduct]()
    @Published var transactionState: SKPaymentTransactionState?
    @Published var transactionDates = [Date]()
    
    enum NetworkError : Error {
        case httpError
    }
    
    enum AppleVerificationEnvironment {
        case sandBox, production
    }
    
    let productIDs = ["Grow.IAP.PemiumAddFree"]
    
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
    
    func getProducts() {
        print("Start requesting products ...")
        self.myProducts = [SKProduct]()
        let request = SKProductsRequest(productIdentifiers: Set(self.productIDs))
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Did receive response")
        
        if !response.products.isEmpty {
            for fetchedProduct in response.products {
                DispatchQueue.main.async {
                    self.myProducts.append(fetchedProduct)
                }
            }
        }
        
        for invalidIdentifier in response.invalidProductIdentifiers {
            print("Invalid identifiers found: \(invalidIdentifier)")
        }
    }
    
    func purchaseProduct(product: SKProduct) {
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            print("User can't make payment.")
        }
    }
    
    func restoreProducts() {
        print("Restoring products ...")
        SKPaymentQueue.default().restoreCompletedTransactions()
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
    
    func createAppleURL(requestData: [String : Any], url: URL) -> URLRequest {
        
        let httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])
        
        var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = httpBody
        
        return request
    }
    
    func verifyReceipt(environment: AppleVerificationEnvironment) throws {
        
        let sandBoxURLString = "https://sandbox.itunes.apple.com/verifyReceipt"
        let productionURLString = "https://buy.itunes.apple.com/verifyReceipt"
        var urlString = ""
        
        if environment == .production {
            urlString = productionURLString
        } else {
            urlString = sandBoxURLString
        }
        
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptString = try? Data(contentsOf: receiptURL).base64EncodedString(),
              let url = URL(string: urlString)
            else {
              return
            }
        
        let requestData : [String : Any] = ["receipt-data" : receiptString, "password" : "f65239d9ecd64f8ebcaca8cc2ca128e3", "exclude-old-transactions" : true]
        
        let request = createAppleURL(requestData: requestData, url: url)
        
            URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) in
                        
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                    if jsonResponse["status"] as! Int == 21007 {
                          try? self.verifyReceipt(environment: .sandBox)
                      } else {
                          if let date = self.getExpirationDateFromResponse(jsonResponse) {
                              self.transactionDates.append(date)
                      }
                }
                }
            } catch let parseError {
                print(parseError)
            }
        }).resume()
    }
    
    func getExpirationDateFromResponse(_ jsonResponse: NSDictionary) -> Date? {
            
            if let receiptInfo: NSArray = jsonResponse["latest_receipt_info"] as? NSArray {
                
                let lastReceipt = receiptInfo.lastObject as! NSDictionary
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
                
                if let expiresDate = lastReceipt["expires_date"] as? String {
                    return formatter.date(from: expiresDate)
                }
                return nil
            }
            else {
                return nil
            }
        }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                transactionState = .purchasing
            case .purchased:
                UserDefaults.standard.setValue(true, forKey: transaction.payment.productIdentifier)
                transactionState = .purchased
                try? verifyReceipt(environment: .production)
                queue.finishTransaction(transaction)
            case .restored:
                UserDefaults.standard.setValue(true, forKey: transaction.payment.productIdentifier)
                try? verifyReceipt(environment: .production)
                transactionState = .restored
                queue.finishTransaction(transaction)
            case .failed, .deferred:
                print("Payment Queue Error: \(String(describing: transaction.error))")
                    queue.finishTransaction(transaction)
                    transactionState = .failed
                    default:
                    queue.finishTransaction(transaction)
            }
        }
    }
    
}

extension String {
//: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }

//: ### Base64 decoding a string
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
