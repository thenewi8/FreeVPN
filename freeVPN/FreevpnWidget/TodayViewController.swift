//
//  TodayViewController.swift
//  HideMyAssWidget
//
//  Created by zhou ligang on 17/11/2016.
//  Copyright © 2016 zhouligang. All rights reserved.
//

import UIKit
import NotificationCenter
import VPNKit
import SnapKit

class TodayViewController: UIViewController, NCWidgetProviding {
    
    var label: UILabel!
    var button: VPNButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        button = VPNButton(frame: CGRect(x: 10.0, y: 10.0, width: 80, height: 80))
        print(button.title)
        button.titleSize = 10
        view.addSubview(button)
        
        let userDefaults = UserDefaults(suiteName: "group.FreedomVPN")
        let country = userDefaults?.string(forKey: "country")
        let country_cn = userDefaults?.string(forKey: "country_cn")
        
        label = UILabel()
        
        let pre = NSLocale.preferredLanguages[0]
        if pre.contains("zh") {
            label.text = country_cn
        }else{
            label.text = country
        }
        
        label.numberOfLines = 1
        label.textAlignment = .center
        label.sizeToFit()
        view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalTo(view)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        let userDefaults = UserDefaults(suiteName: "group.FreedomVPN")
        let country = userDefaults?.string(forKey: "country")
        let country_cn = userDefaults?.string(forKey: "country_cn")
        
        let pre = NSLocale.preferredLanguages[0]
        if pre.contains("zh") {
            label.text = country_cn
        }else{
            label.text = country
        }
        completionHandler(NCUpdateResult.newData)
    }
    
}
