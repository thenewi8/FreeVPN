//
//  AppDelegate+Plan.swift
//  freevpn_mac
//
//  Created by zhou ligang on 06/10/2016.
//  Copyright © 2016 zhou ligang. All rights reserved.
//

import Cocoa
import StoreKit
import Alamofire

extension AppDelegate {

    func getPlans(){
        PlanProducts.store.requestProducts{success, products in
            if success {
                self.plans = products!
                self.plans.sort(by: {$0.price.doubleValue < $1.price.doubleValue})

                self.setMenu()
            }
        }
    }
    
    func getPlanMenu() -> NSMenu{
        let plansMenu = NSMenu(title: "Plans")
        for (idx, plan) in self.plans.enumerated(){
            if idx > 0{
                plansMenu.addItem(NSMenuItem.separator())
            }
            
            var menuitem: NSMenuItem? = nil
            if locale.contains("zh") {
                menuitem = NSMenuItem(title: plan.localizedPrice() + ": " + plan.localizedDescription, action: #selector(AppDelegate.selectOnePlan(_:)), keyEquivalent: "")
            }else{
                menuitem = NSMenuItem(title: plan.localizedPrice() + ": " + plan.localizedDescription, action: #selector(AppDelegate.selectOnePlan(_:)), keyEquivalent: "")
            }
            menuitem?.tag = idx
            menuitem?.image = NSImage(named: "Sale")
            plansMenu.addItem(menuitem!)
        }
        return plansMenu
    }
    
    func selectOnePlan(_ sender: AnyObject?){
        if self.purchasing == 1{
            return
        }
        self.purchasing = 1
        let menuitem = sender as! NSMenuItem
        let index = menuitem.tag

        Alamofire.request(FreeVPN.Router.postBeforePay(loginUserName, self.plans[index].productIdentifier)).validate().responseJSON { [unowned self] response in
            switch response.result{
            case .failure(_):
                self.purchasing = 0
                break
            case .success(let value):
                let errcode = (value as AnyObject).value(forKey: "errcode") as! Int
                if errcode == 200{
                    let allow = (value as AnyObject).value(forKey: "allow") as! Int
                    if allow == 1{
                        let product = self.plans[index]
                        PlanProducts.store.buyProduct(product)
                        
//                        Utils.makeNotification("You Are Making Purchase", "Please Waiting and Check Out")
                    }else{
                        Utils.makeNotification("Pay Error", "Do not Purchase Too Frequent")
                        self.purchasing = 0
                    }
                }
                self.purchasing = 0
                break
            }
        }
    }
    
    func didPurchase(_ notification: Notification){
        guard let productID = notification.object as? String else { return }

        Utils.makeNotification(NSLocalizedString("thanks", comment: "thanks"), NSLocalizedString("forSupport", comment: ""))
//        Alamofire.request(FreeVPN.Router.postPay(loginUserName, productID)).validate().responseJSON { [unowned self] response in
//            switch response.result{
//            case .success(let value):
//                let errcode = (value as AnyObject).value(forKey: "errcode") as! Int
//                if errcode != 200{
//                    
//                    Utils.makeNotification(NSLocalizedString("payError", comment: "payError"), NSLocalizedString("payError", comment: "payError"))
//                }else{
//                    timelimit = (value as AnyObject).value(forKey: "timelimit") as! String
//                    let fromtime = (value as AnyObject).value(forKey: "fromtime") as! String
//                    self.setMenu()
//                    
//                    Utils.makeNotification("success", NSLocalizedString("deadlineTime", comment: "deadlineTime") + ": " + NSLocalizedString("from", comment: "from") + " " + fromtime + " " + NSLocalizedString("to", comment: "to") + " " + timelimit)
//                }
//                break
//            case .failure(let error):
//                print("error: \(error)")
//                Utils.makeNotification(NSLocalizedString("payError", comment: "payError"), NSLocalizedString("payError", comment: "payError"))
//            }
//        }
    }
    
    func didPurchaseFailed(_ notification: Notification){
        Utils.makeNotification(NSLocalizedString("PayError2", comment: "payError"), NSLocalizedString("PayError2", comment: "payError"))
    }
}
