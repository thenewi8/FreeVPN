//
//  SettingViewController.swift
//  freevpn
//
//  Created by ligulfzhou on 3/22/16.
//  Copyright © 2016 ligulfzhou. All rights reserved.
//

import UIKit 
import iAd
import DZNEmptyDataSet

class SettingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate{

//    var slideView: UIScrollView!
    var segment: UISegmentedControl!
//    var slider1: iOSSettingView!
    var settingTableView: UITableView!
    let iosSettingStrings = [NSLocalizedString("iosSetting1", comment: "ios Setting step 1"),  NSLocalizedString("iosSetting2", comment: "ios setting step 2")]
    let iosSettingImages = ["ios_1", "ios_2"]
    let macSettingStrings = [NSLocalizedString("macSettings1", comment: "macSettings1"), NSLocalizedString("macSettings2", comment: "macSettings2"), NSLocalizedString("macSettings3", comment: "macSettings3"), NSLocalizedString("macSettings4", comment: "macSettings4"), NSLocalizedString("macSettings5", comment: "macSettings5"), NSLocalizedString("macSettings6", comment: "macSettings6"), NSLocalizedString("macSettings7", comment: "macSettings7")]
    let macSettingImages = ["mac_1", "mac_2", "mac_3", "mac_4", "mac_5", "mac_6", "mac_7"]
    
    let settingTableCellReuseIdentifier = "SettingTableCellReuseIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segment = UISegmentedControl(items: ["iOS", "Mac", "More"])
        segment.addTarget(self, action: #selector(SettingViewController.segmentValueChange(_:)), forControlEvents: .ValueChanged)
        segment.selectedSegmentIndex = 0
        self.navigationItem.titleView = segment
        
        settingTableView = UITableView(frame: self.view.bounds, style: .Grouped)
        settingTableView.registerClass(SettingsTableCell.classForCoder(), forCellReuseIdentifier: settingTableCellReuseIdentifier)
        settingTableView.dataSource = self
        settingTableView.delegate = self
        settingTableView.emptyDataSetSource = self
        settingTableView.emptyDataSetDelegate = self
        self.view.addSubview(settingTableView)
        
        settingTableView.estimatedRowHeight = 300
        settingTableView.rowHeight = UITableViewAutomaticDimension
        
        settingTableView.setNeedsLayout()
        settingTableView.layoutIfNeeded()
    }
    
    //Mark: tableview datasource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segment.selectedSegmentIndex == 0{
            return iosSettingStrings.count
        }else if segment.selectedSegmentIndex == 1{
            return macSettingStrings.count
        }else{
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //        let cell = tableView.dequeueReusableCellWithIdentifier(settingTableCellReuseIdentifier, forIndexPath: indexPath) as! SettingsTableCell
        let cell = SettingsTableCell()
        if segment.selectedSegmentIndex == 0{
            cell.labelText = iosSettingStrings[(indexPath as NSIndexPath).row]
            cell.img = iosSettingImages[(indexPath as NSIndexPath).row]
        }else{
            cell.labelText = macSettingStrings[(indexPath as NSIndexPath).row]
            cell.img = macSettingImages[(indexPath as NSIndexPath).row]
        }
        cell.selectionStyle = .None
        return cell

    }
    
    //MARK: UISegment Value Change target
    func segmentValueChange(sender: UISegmentedControl){
//        settingTableView.setNeedsLayout()
//        settingTableView.layoutIfNeeded()
        settingTableView.reloadData()
    }
    
    func tableView(tableView: UITableView, didSelectRowAt indexPath: NSIndexPath) {
        if segment.selectedSegmentIndex == 2{
            return
        }
        
        let imageSwipeVC = ImageSwipeViewController()
        if segment.selectedSegmentIndex == 0{
            imageSwipeVC.imgNameList = ["ios_1", "ios_2"]
        }else {
            imageSwipeVC.imgNameList = ["mac_1", "mac_2", "mac_3", "mac_4", "mac_5", "mac_6", "mac_7"]
        }
        imageSwipeVC.imgIdx = (indexPath as NSIndexPath).row
        imageSwipeVC.modalTransitionStyle = .CoverVertical
        imageSwipeVC.modalPresentationStyle = .CurrentContext
        self.navigationController!.presentViewController(imageSwipeVC, animated: true, completion: nil)
    }
    
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "icon")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attrString = NSAttributedString(string: NSLocalizedString("emptySettingTips", comment: "emptySettingTips"), attributes:[
            NSFontAttributeName: UIFont.systemFontOfSize(13),
            NSForegroundColorAttributeName: UIColor.redColor(),
            ])
        return attrString
    }
}

