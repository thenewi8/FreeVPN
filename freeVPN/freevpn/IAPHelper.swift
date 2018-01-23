/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import StoreKit
import Alamofire

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> ()

open class IAPHelper : NSObject  {
    
    fileprivate let productIdentifiers: Set<ProductIdentifier>
    fileprivate var purchasedProductIdentifiers = Set<ProductIdentifier>()
    
    fileprivate var productsRequest: SKProductsRequest?
    fileprivate var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    
    static let IAPHelperPurchaseNotification = "IAPHelperPurchaseNotification"
    static let IAPHelperPurchaseFailedNotification = "IAPHelperPurchaseFailedNotification"
    
    public init(productIds: Set<ProductIdentifier>) {
        
        self.productIdentifiers = productIds
        /*
        for productIdentifier in productIds {
            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
                print("Previously purchased: \(productIdentifier)")
            } else {
                print("Not purchased: \(productIdentifier)")
            }
        }
        */
        super.init()
        
        SKPaymentQueue.default().add(self)
    }
}

// MARK: - StoreKit API
extension IAPHelper {
    
    public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func buyProduct(_ product: SKProduct) {
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    //public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
    //   return purchasedProductIdentifiers.contains(productIdentifier)
    //}
    
    public class func canMakePayments() -> Bool {
        return true
    }
    
    public func restorePurchases() {
        print("sdflkjasdlfkjalskdfj;aldksjf")
    }
}


// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Loaded list of products...")
        let products = response.products
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        //for p in products {
        //    print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue) \(p.localizedDescription)")
        //}
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: IAPHelper.IAPHelperPurchaseFailedNotification)))
        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    fileprivate func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}


// MARK: - SKPaymentTransactionObserver
extension IAPHelper: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                print(".purchased")
                do{
                    try self.completeTransaction(transaction)
                }catch _ {
                    return
                }
                break
            case .failed:
                print(".failed")
                failedTransaction(transaction)
                break
            case .restored:
                print(".restored")
                restoreTransaction(transaction)
                break
            case .deferred:
                print(".deferred")
                break
            case .purchasing:
                print(".purchasing")
                break
            }
        }
    }
    
    fileprivate func completeTransaction(_ transaction: SKPaymentTransaction) throws {
        print("completeTransaction...")
        
        validateReceipt(url: .production) { (status) in
            print("status:  \(status)")
            if status
            {
                self.deliverPurchaseNotificatioForIdentifier(transaction.payment.productIdentifier)
                SKPaymentQueue.default().finishTransaction(transaction)
            }
            else
            {
                print("Something bad happened")
                NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: IAPHelper.IAPHelperPurchaseFailedNotification)))
            }
        }
    }
    
    fileprivate func restoreTransaction(_ transaction: SKPaymentTransaction) {
        print("restore....")
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        print("restoreTransaction... \(productIdentifier)")
        deliverPurchaseNotificatioForIdentifier(productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    fileprivate func failedTransaction(_ transaction: SKPaymentTransaction) {
        print("failedTransaction...")
        if let transactionError = transaction.error as? NSError{
            if transactionError.code != SKError.paymentCancelled.rawValue {
                print("Transaction Error: \(transaction.error?.localizedDescription)")
            }
        }
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: IAPHelper.IAPHelperPurchaseFailedNotification)))
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    fileprivate func deliverPurchaseNotificatioForIdentifier(_ identifier: String?) {
        guard let identifier = identifier else { return }
        
        purchasedProductIdentifiers.insert(identifier)
        UserDefaults.standard.set(true, forKey: identifier)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: Notification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification), object: identifier)
    }
}


extension SKProduct {
    
    func localizedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)!
    }
    
}

enum ReceiptURL : String
{
    case sandbox = "https://sandbox.itunes.apple.com/verifyReceipt"
    case production = "https://buy.itunes.apple.com/verifyReceipt"
    case myServer = "your server"
    
}


func validateReceipt(url: ReceiptURL, completion : @escaping (_ status : Bool) -> ())  {
    print("verify ing...")
    let receiptUrl = Bundle.main.appStoreReceiptURL
    let receipt: NSData = NSData(contentsOf: receiptUrl!)!
    let receiptdata: NSString = receipt.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) as NSString
    let dict = ["receipt-data" : receiptdata]
    let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: JSONSerialization.WritingOptions(rawValue: 0))
    let request = NSMutableURLRequest(url: NSURL(string: url.rawValue)! as URL)
    
    let session = URLSession.shared
    request.httpMethod = "POST"
    request.httpBody = jsonData
    
    let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error  in
        if let dataR = data
        {
            handleData(responseDatas: dataR as NSData, completion: { status in
                completion(status)
            })
        }
    })
    
    task.resume()
}

func handleData(responseDatas : NSData, completion : @escaping (_ status : Bool) -> ())
{
    if let json = try! JSONSerialization.jsonObject(with: responseDatas as Data, options: JSONSerialization.ReadingOptions.mutableLeaves) as? NSDictionary
    {
        print("status: \(json.value(forKeyPath: "status") as? Int)")
        if let value = json.value(forKeyPath: "status") as? Int
        {
            if value == 0
            {
                let receipt = json.value(forKey: "receipt") as! [String: AnyObject]
                let in_apps = receipt["in_app"]
                // Alamofire.request()
                completion(true)
            }else if value == 21007{
                validateReceipt(url: .sandbox, completion: completion)
            }
            else
            {
                completion(false)
            }
        }
        else
        {
            completion(false)
        }
    }
}

extension NSTimeZone{
    
}
