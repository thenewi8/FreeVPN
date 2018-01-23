//
//  Utils.swift
//  freevpn_mac
//
//  Created by zhou ligang on 07/10/2016.
//  Copyright © 2016 zhou ligang. All rights reserved.
//

import Cocoa

class Utils: NSObject {

    static func makeNotification(_ title: String, _ information: String){
        let notification = NSUserNotification.init()
        
        // set the title and the informative text
        notification.title = title
        notification.informativeText = information
//        notification.contentImage = NSImage(named: "menu_icon")
        
        // put the path to the created text file in the userInfo dictionary of the notification
        notification.userInfo = [:]
        
        // use the default sound for ;a notification
        notification.soundName = NSUserNotificationDefaultSoundName
        
        // if the user chooses to display the notification as an alert, give it an action button called "View"
        notification.hasActionButton = true
        notification.actionButtonTitle = "View"
        
        // Deliver the notification through the User Notification Center
        NSUserNotificationCenter.default.deliver(notification)
    }
}
