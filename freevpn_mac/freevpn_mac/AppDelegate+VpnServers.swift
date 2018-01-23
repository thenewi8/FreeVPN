//
//  AppDelegate+Servers.swift
//  freevpn_mac
//
//  Created by zhou ligang on 07/10/2016.
//  Copyright © 2016 zhou ligang. All rights reserved.
//

import Cocoa
import Alamofire
import NetworkExtension

extension AppDelegate {
    
    func connectVPN(_ sender: AnyObject?){
        self.manager.connection.stopVPNTunnel()
        let menuitem = sender as! NSMenuItem
        currentIdx = menuitem.tag
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(AppDelegate._connectVPN), userInfo: nil, repeats: false)
    }
    
    func _connectVPN(){
        if self.myservers.count <= 0{
            self.fetchServers()
            return
        }
        currentServer = self.myservers[currentIdx]
        self.manager.loadFromPreferences { [unowned self] (error: Error?) -> Void in
            if error != nil{
                print("load error: \(error)")
            }else{
                let password = KeyChainUtil.get(loginUserPasswordKey)
                
                let vpnProtocol = NEVPNProtocolIKEv2()
                vpnProtocol.username = loginUserName
                vpnProtocol.passwordReference = password
                vpnProtocol.serverAddress = currentServer!.ip
                vpnProtocol.authenticationMethod = .none
                vpnProtocol.remoteIdentifier = currentServer!.remote_id
                vpnProtocol.localIdentifier = loginUserName
                vpnProtocol.useExtendedAuthentication = true
                vpnProtocol.disconnectOnSleep = false
                self.manager.isEnabled = true
                self.manager.protocolConfiguration = vpnProtocol
                self.manager.saveToPreferences(completionHandler: { (error: Error?) -> Void in
                    if error != nil{
                        print("save error: \(error)")
                    }else{
                        do{
                            try self.manager.connection.startVPNTunnel()
                        }catch{
                            print("connect error: \(error)")
                        }
                    }
                })
            }
        }
    }

    func fetchServers(){
        if self.myservers.count > 0{
            self.setMenu()
            return
        }
        
        Alamofire.request(FreeVPN.Router.getServer()).validate().responseCollection {
            [unowned self] (response: DataResponse<[Server]>) in
            
            if let result = response.result.value{
                self.myservers = []
                self.myservers = result
                
                self.setMenu()
            }
        }
    }
    
    func getServermenu() -> NSMenu{
        let serversMenu = NSMenu(title: "VPNs")
        for (idx, server) in self.myservers.enumerated(){
            if idx > 0{
                serversMenu.addItem(NSMenuItem.separator())
            }
            
            var menuitem: NSMenuItem? = nil
            if locale.contains("zh") {
                menuitem = NSMenuItem(title: server.country_cn + ", " + server.city_cn, action: #selector(AppDelegate.connectVPN(_:)), keyEquivalent: "")
            }else{
                menuitem = NSMenuItem(title: server.city + ", " + server.country, action: #selector(AppDelegate.connectVPN(_:)), keyEquivalent: "")
            }
            menuitem?.tag = idx
            menuitem?.image = NSImage(named: server.country)
            serversMenu.addItem(menuitem!)
        }
        return serversMenu
    }
    
    func vpnStatusChangeObserver(){
        manager.loadFromPreferences { [unowned self] (error: Error?) -> Void in
            if error != nil{
                NSLog("load preference error in vpnStatusChangeObserver func:   \(error)")
            }else{
                switch self.manager.connection.status{
                case .connecting:
                    if let button = self.statusItem.button {
                        button.title = NSLocalizedString("connectingText", comment: "connecting")
                    }
                    break
                case .connected:
                    if let button = self.statusItem.button {
                        button.title = NSLocalizedString("connectedText", comment: "connectedText")
                    }
                    vpnStatus = 1
                    self.setMenu()
                    
                    break
                case .disconnecting:
                    if let button = self.statusItem.button {
                        button.title = NSLocalizedString("disconnectingText", comment: "disconnectingText")
                    }
                    break
                case .disconnected:
                    if let button = self.statusItem.button {
                        button.title = NSLocalizedString("disconnectedText", comment: "disconnectedText")
                    }
                    vpnStatus = 0
                    self.setMenu()
                    break
                default:
                    break
                }
            }
        }
    }
    
    func getCurrentVpnStatus(){
        self.manager.loadFromPreferences { [unowned self] (error: Error?) -> Void in
            if error != nil{
                NSLog("\(error)")
                if let button = self.statusItem.button {
                    button.title = NSLocalizedString("disconnectedText", comment: "disconnectedText")
                }
            }else{
                switch self.manager.connection.status{
                case .connected:
                    if let button = self.statusItem.button {
                        button.title = NSLocalizedString("connectedText", comment: "connectedText")
                    }
                    vpnStatus = 1
                    self.setMenu()
                    break
                case .disconnected:
                    if let button = self.statusItem.button {
                        button.title = NSLocalizedString("disconnectedText", comment: "disconnectedText")
                    }
                    vpnStatus = 0
                    self.setMenu()
                    break
                default:
                    if let button = self.statusItem.button {
                        button.title = NSLocalizedString("disconnectedText", comment: "disconnectedText")
                    }
                    break
                }
            }
        }
    }
    
    func disconnectVPN(){
        self.manager.connection.stopVPNTunnel()
    }
}
