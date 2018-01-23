//
//  MacSettingView.swift
//  freevpn
//
//  Created by ligulfzhou on 4/3/16.
//  Copyright © 2016 ligulfzhou. All rights reserved.
//

import UIKit

enum SettingView: Int{
    case ios_setting_view=1
    case mac_setting_view=2
}

protocol SettingImageDelegate {
    func didSelectImageAt(indexPath: NSIndexPath, whichSettingView: SettingView)
}

class iOSSettingView: UIView, UITableViewDataSource, UITableViewDelegate {
    
    var tableview:UITableView?
    let settingTableCellIdentifier = "setting_table_cell_identifier"
    let strs = ["1: 在设置->通用->vpn， 点击'添加vpn配置'， 如图填写;",  "2: 在设置->VPN里，点击连接"]
    let images = ["ios_1", "ios_2"]
    
    var delegate: SettingImageDelegate?
    
    override init(frame: CGRect) {
        NSLog("uiview init function get called")
        super.init(frame: frame)

        tableview = UITableView(frame: self.bounds, style: .Grouped)
        tableview?.registerClass(SettingsTableCell.classForCoder(), forCellReuseIdentifier: settingTableCellIdentifier)
        self.addSubview(tableview!)
        
        tableview!.delegate = self
        tableview!.dataSource = self
        
        tableview?.estimatedRowHeight = 300
        tableview?.rowHeight = UITableViewAutomaticDimension
        
        tableview?.setNeedsLayout()
        tableview?.layoutIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func addSubview(view: UIView) {
        super.addSubview(view)
    }
    
    override func didMoveToSuperview(){
        super.didMoveToSuperview()
        tableview?.reloadData()
        
        tableview?.setNeedsLayout()
        tableview?.layoutIfNeeded()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return strs.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = SettingsTableCell()
        cell.labelText = strs[(indexPath as NSIndexPath).row]
        cell.img = images[(indexPath as NSIndexPath).row]
        cell.selectionStyle = .None
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAt indexPath: NSIndexPath) {
        self.delegate?.didSelectImageAt(indexPath, whichSettingView: .ios_setting_view)
    }

}
