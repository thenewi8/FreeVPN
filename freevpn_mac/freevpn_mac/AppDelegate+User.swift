//
//  AppDelegate+User.swift
//  freevpn_mac
//
//  Created by zhou ligang on 07/10/2016.
//  Copyright © 2016 zhou ligang. All rights reserved.
//

import Cocoa
import Alamofire

extension AppDelegate {

    func login(_ sender: AnyObject?){
        loginWindowController.showWindow(sender)
        NSApplication.shared().activate(ignoringOtherApps: true)
    }
    
    func afterLogin(_ notification: Notification){
        timelimit = (notification as NSNotification).userInfo!["timelimit"] as! String
        self.setMenu()
        self.fetchServers()
    }
    
    func getUserInfo(){
        Alamofire.request(FreeVPN.Router.getUserInfo(loginUserName)).validate().responseJSON { [unowned self] response in
            switch response.result{
            case .success(let value):
                let email = (value as AnyObject).value(forKey: "email") as! String
                KeyChainUtil.store(loginUserEmailKey, value: email)
                
                timelimit = (value as AnyObject).value(forKey: "timelimit") as! String
                self.setMenu()
                
//                loginUserName = name
//                loginUserPassword = password
//                KeyChainUtil.store(loginUserNameKey, value: name)
//                KeyChainUtil.store(loginUserPasswordKey, value: password)
                
                break
            case .failure(let error):
                print("error: \(error)")
                break
            }
        }

    }
    
    func getXsrfToken(){
        Alamofire.request(FreeVPN.Router.getXsrfToken()).validate().responseJSON { response in
            switch response.result{
            case .success(let value):
                xsrfToken = (value as AnyObject).value(forKey: "token") as! String
                print("fetched XSRF: \(xsrfToken)")
            case .failure(let error):
                print("error: \(error)")
            }
        }
    }
    
    func checkin(){
        Alamofire.request(FreeVPN.Router.postCheckIn(loginUserName)).validate().responseJSON { [unowned self] response in
            switch response.result{
            case .success(let value):
                let errcode = (value as AnyObject).value(forKey: "errcode") as! Int
                if errcode == 200{
                    let reward = (value as AnyObject).value(forKey: "reward") as! Int
                    timelimit = (value as AnyObject).value(forKey: "timelimit") as! String
                    self.setMenu()
                    
                    Utils.makeNotification(NSLocalizedString("checkInSuccessText", comment: "checkInSuccessText"), NSLocalizedString("congratulationsOnCheckIn", comment: "congratulationsOnCheckIn") + String(reward))
                    
                }else{
                    let errmsg = (value as AnyObject).value(forKey: "errmsg") as! String
                    let localizedErrMsg = NSLocalizedString(errmsg, comment: "errmsg")
                    
                    Utils.makeNotification(NSLocalizedString("checkInFailureText", comment: "checkInFailureText"), NSLocalizedString(localizedErrMsg, comment: localizedErrMsg))
                }
                break
            case .failure(let error):
                print("\(error)")
                Utils.makeNotification(NSLocalizedString("checkInFailureText", comment: "checkInFailureText"), NSLocalizedString("checkInFailed", comment: "checkInFailed"))
                break
            }
            
        }
    }
    
    func logout(){
        KeyChainUtil.store(loginUserNameKey, value: "")
        KeyChainUtil.store(loginUserPasswordKey, value: "")
        loginUserName = ""
        loginUserPassword = ""
        self.setMenu()
        self.disconnectVPN()
    }
}
