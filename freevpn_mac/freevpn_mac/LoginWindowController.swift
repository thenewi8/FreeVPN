//
//  LoginWindowController.swift
//  freevpn_mac
//
//  Created by zhou ligang on 03/10/2016.
//  Copyright © 2016 zhou ligang. All rights reserved.
//

import Cocoa
import Alamofire

class LoginWindowController: NSWindowController {

    
    @IBOutlet weak var userTextField: NSTextFieldCell!
    
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
    
    @IBAction func register(_ sender: AnyObject) {
        NSWorkspace.shared().open(URL(string: "http://freevpn.ligulfzhou.com")!)
    }
    
    @IBAction func login(_ sender: AnyObject) {
        let name = userTextField.stringValue
        let password = passwordTextField.stringValue
        print("\(name), \(password)")
        
        Alamofire.request(FreeVPN.Router.postLogin(name, password)).validate().responseJSON { response in
            switch response.result{
            case .failure(_):
                break
            case .success(let value):
                let errcode = (value as AnyObject).value(forKey: "errcode") as! Int
                if errcode == 200 {
                    loginUserName = name
                    loginUserPassword = password
                    KeyChainUtil.store(loginUserNameKey, value: name)
                    KeyChainUtil.store(loginUserPasswordKey, value: password)
                    let timelimit = (value as AnyObject).value(forKey: "timelimit") as! String
                    let data = ["timelimit": timelimit]
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: userLoginNotification), object: nil, userInfo: data)
                    Utils.makeNotification(NSLocalizedString("success", comment: "success"), NSLocalizedString("loginSuccess", comment: "loginSuccess"))
                    self.window?.close()
                    
                }else{
                    Utils.makeNotification(NSLocalizedString("failed", comment: "failed"), NSLocalizedString("loginFailed", comment: "loginFailed"))
                }
            }
        }
    }

}
