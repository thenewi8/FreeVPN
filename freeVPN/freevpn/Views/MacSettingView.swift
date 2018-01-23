//
//  MacSettingView.swift
//  freevpn
//
//  Created by ligulfzhou on 4/3/16.
//  Copyright © 2016 ligulfzhou. All rights reserved.
//

import UIKit

class MacSettingView: UIView, UITableViewDataSource, UITableViewDelegate {
    
    var tableview:UITableView?
    let settingTableCellIdentifier = "setting_table_cell_identifier"
    let strs = ["1: 在网络设置界面， 点击+;\n2: 在弹框中选择接口类型--vpn， vpn类型--pptp, 服务名称可以任意", "3: 填写服务器地址和账号名", "4: 点击验证设置\n 5: 并选择密码，填入账号的密码", "6: 点击更多", "7: 勾选通过vpn发送所有的流量", "8: 点击保存\n9: 店家保存配置", "10: 勾选在菜单栏显示vpn的状态\n11: 最后点击链接"]
    let images = ["mac_1", "mac_2", "mac_3", "mac_4", "mac_5", "mac_6", "mac_7"]
    
    var delegate: SettingImageDelegate?
    
    override init(frame: CGRect) {
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
//        let cell = tableView.dequeueReusableCellWithIdentifier(settingTableCellIdentifier, forIndexPath: indexPath) as! SettingsTableCell
        let cell = SettingsTableCell()
        cell.labelText = strs[(indexPath as NSIndexPath).row]
        cell.img = images[(indexPath as NSIndexPath).row]
        cell.selectionStyle = .None
        return cell
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAt indexPath: NSIndexPath) -> CGFloat {
        return 700
    }
    
    func tableView(tableView: UITableView, didSelectRowAt indexPath: NSIndexPath) {
        self.delegate?.didSelectImageAt(indexPath, whichSettingView: .mac_setting_view)
    }

}
