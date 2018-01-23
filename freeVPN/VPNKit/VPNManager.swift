//
//  VPNManager.swift
//  HideMyAssVPN
//
//  Created by zhou ligang on 17/11/2016.
//  Copyright © 2016 zhouligang. All rights reserved.
//

import Foundation
import NetworkExtension

private let instance = VPNManager()

open class VPNManager{
    
    private var manager: NEVPNManager {
        return NEVPNManager.shared()
    }
    
    public var status: NEVPNStatus {
        return manager.connection.status
    }
    
    public class var sharedVPNManager: VPNManager{
        return instance
    }
    
    public func getStatus(complete: @escaping (NEVPNStatus?)-> ()){
        manager.loadFromPreferences { (error) in
            guard error == nil else {
                return
            }
            complete(self.manager.connection.status)
        }
    }
    
    public func toggle(){
        manager.loadFromPreferences { [weak self](error) in
            guard error == nil else {
                return
            }
            let status = (self?.manager.connection.status)!
            switch status{
            case .connected:
                self?.disconnectVPN()
            case .disconnected:
                self?._saveAndConnect()
            default:
                self?._saveAndConnect()
            }
        }
    }
    
    public func saveAndConnect(){
        self._saveAndConnect()
    }
    
    private func _saveAndConnect(){
        
        manager.loadFromPreferences { [weak self] (error) in
            
            guard error == nil else{
                return
            }
            let userDefaults = UserDefaults(suiteName: "group.FreedomVPN")
            let username = userDefaults?.string(forKey: "username")
            let password = userDefaults?.string(forKey: "password")
            let ip = userDefaults?.string(forKey: "ip")
            let remote_id = userDefaults?.string(forKey: "remote_id")
            
            print("\(username), \(password), \(ip), \(remote_id)")
            KeyChainUtil.store("password", value: password!)
            let passwordRef = KeyChainUtil.get("password")
            
            let vpnProtocol = NEVPNProtocolIKEv2()
            vpnProtocol.username = username
            vpnProtocol.passwordReference = passwordRef
            vpnProtocol.serverAddress = ip
            vpnProtocol.authenticationMethod = .none
            vpnProtocol.remoteIdentifier = remote_id
            vpnProtocol.localIdentifier = username
            vpnProtocol.useExtendedAuthentication = true
            vpnProtocol.disconnectOnSleep = false
            
            self?.manager.isEnabled = true
            
            self?.manager.protocolConfiguration = vpnProtocol
            
            self?.manager.saveToPreferences(completionHandler: { (error) in
                guard error==nil else {
                    return
                }
                do{
                    try self?.manager.connection.startVPNTunnel()
                }catch{
                    print("connection error \(error)")
                    return
                }
            })
        }
    }
    
    public func disconnectVPN(){
        
        manager.connection.stopVPNTunnel()
    }
}
