//
//  AppDelegate.swift
//  freevpn_mac
//
//  Created by zhou ligang on 9/17/16.
//  Copyright © 2016 zhou ligang. All rights reserved.
//

import Cocoa
import Alamofire
import StoreKit
import NetworkExtension

var locale = Locale.preferredLanguages[0]
var isLogin = 0
var currentIdx = -1
var currentServer: Server? = nil

let loginUserNameKey = "LoginUserNameKey"
var loginUserName = KeyChainUtil.getStringValue(loginUserNameKey)
let loginUserPasswordKey = "LoginUserPasswordKey"
var loginUserPassword = KeyChainUtil.getStringValue(loginUserPasswordKey)
let loginUserEmailKey = "loginUserEmailKey"
var timelimit = ""

let userLoginNotification = "UserLoginNotification"

var vpnStatus: Int = 0   //vpn连接状态， 用于设置第一个菜单栏是连接还是断开   1是vpn连接状态

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    
    let manager: NEVPNManager = NEVPNManager.shared()
    var purchasing = 0
    
    var myservers = [Server]()
    var plans = [SKProduct]()
    lazy var loginWindowController: NSWindowController = LoginWindowController(windowNibName: "LoginWindowController")
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let button = statusItem.button {
            button.image = NSImage(named: "menu_icon")
            button.imagePosition = .imageLeft
            button.title = ""
        }
        
        loginUserName = "client1"
        loginUserPassword = "password"
        KeyChainUtil.store(loginUserNameKey, value: "client1")
        KeyChainUtil.store(loginUserPasswordKey, value: "password")
        
        self.setMenu()      // 设置菜单，根据当前登录状态
        self.getXsrfToken()
//        self.getPlans()
        self.getCurrentVpnStatus()   //获取当前vpn的状态，设置statusitem的文字, 还有更新vpn状态的菜单栏
        if loginUserName == "" || loginUserPassword == ""{
            self.getUserInfo()
        }
        self.fetchServers()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.vpnStatusChangeObserver), name: Notification.Name.NEVPNStatusDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.afterLogin(_:)), name: Notification.Name(rawValue: userLoginNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didPurchase(_:)), name: Notification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.didPurchaseFailed(_:)), name: Notification.Name(rawValue: IAPHelper.IAPHelperPurchaseFailedNotification), object: nil)
        NSUserNotificationCenter.default.delegate = self
    }
    
    func setMenu(){
        let menu = NSMenu()
        var vpnStatusMenuItem = NSMenuItem(title: NSLocalizedString("youAreDisconnected", comment: "youAreDisconnected"), action: nil, keyEquivalent: "")
        var vpnConnectMenuItem = NSMenuItem(title: NSLocalizedString("connectToVPN", comment: "connectToVPN"), action: #selector(AppDelegate.connectVPN(_:)), keyEquivalent: "c")
        if vpnStatus == 1{
            vpnStatusMenuItem = NSMenuItem(title: NSLocalizedString("youAreConnected", comment: "youAreConnected"), action: nil, keyEquivalent: "")
            vpnConnectMenuItem = NSMenuItem(title: NSLocalizedString("disconnectToVPN", comment: "disconnectToVPN"), action: #selector(AppDelegate.disconnectVPN), keyEquivalent: "d")
        }
        menu.addItem(vpnStatusMenuItem)
        menu.addItem(vpnConnectMenuItem)
        menu.addItem(NSMenuItem.separator())
        
//        let timeLimitMenuItem = NSMenuItem(title: NSLocalizedString("deadlineTime", comment: "deadlineTime") + ": " + timelimit, action: nil, keyEquivalent: "")
//        menu.addItem(timeLimitMenuItem)
//        
//        let checkInMenuItem = NSMenuItem(title: NSLocalizedString("checkIn", comment: "checkIn"), action: #selector(AppDelegate.checkin), keyEquivalent: "")
//        menu.addItem(checkInMenuItem)
//        menu.addItem(NSMenuItem.separator())
//        
        let serverSubmenu = NSMenuItem(title: NSLocalizedString("chooseVPN", comment: "chooseVPN"), action: nil, keyEquivalent: "")
        serverSubmenu.submenu = self.getServermenu()
        menu.addItem(serverSubmenu)
        
        menu.addItem(NSMenuItem.separator())
        
//        let planSubmenu = NSMenuItem(title: NSLocalizedString("supportMe", comment: "supportMe"), action: nil, keyEquivalent: "")
//        planSubmenu.submenu = self.getPlanMenu()
//        menu.addItem(planSubmenu)
        let contactMeSubmenu = NSMenuItem(title: NSLocalizedString("sendFeedback", comment: "send feedback"), action: #selector(AppDelegate.contactMe(_:)), keyEquivalent: "")
        menu.addItem(contactMeSubmenu)
        
        menu.addItem(NSMenuItem.separator())
//        menu.addItem(NSMenuItem(title: NSLocalizedString("logout", comment: "logout"), action: #selector(AppDelegate.logout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: NSLocalizedString("quit", comment: "quit"), action: #selector(AppDelegate.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        NotificationCenter.default.removeObserver(self)
    }

    func terminate(_ sender: AnyObject?){
        disconnectVPN()
        NSApplication.shared().terminate(sender)
    }
    
    func contactMe(_ sender: AnyObject?){
        let service = NSSharingService(named: NSSharingServiceNameComposeEmail)
        service?.recipients = ["ligulfzhou53@gmail.com"]
        service?.subject = "Feedback"
        service?.perform(withItems: ["Write Your Feedback, Thanks"])

        NSWorkspace.shared().launchApplication("Mail")
    }
}

extension AppDelegate: NSUserNotificationCenterDelegate{

    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}

