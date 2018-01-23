//
//  MainViewController.swift
//  HideMyAssVPN
//
//  Created by zhou ligang on 17/11/2016.
//  Copyright © 2016 zhouligang. All rights reserved.
//

import UIKit
import SnapKit
import Alamofire
import VPNKit
import GoogleMobileAds
import MBProgressHUD


func delayOneMinute(complete: @escaping ()->()){
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(60000)){
        complete()
    }
}

class HomeViewController: UIViewController {
    
    var bannerView: GADBannerView!
    var interstitialAd: GADInterstitial!
    var collectView: UICollectionView!
    var collectionViewIdentifier: String = "collectionViewCellIdentifier"
    var servers = [Server]()
    var hub: MBProgressHUD!
    var selected: Int = 0
    var rated = KeyChainUtil.getStringValue("rated")
    
    var button: UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("title", for: UIControlState.normal)
        btn.addTarget(
            self,
            action: #selector(HomeViewController.connectVPN(sender:)),
            for: .touchUpInside)
        
        btn.sizeToFit()
        return btn
    }

    func cycleInterstitialAd(){
        interstitialAd?.delegate = nil
        interstitialAd = nil
        interstitialAd = GADInterstitial(adUnitID: "ca-app-pub-9174125730777485/2385440057")
        let request = GADRequest()
        request.testDevices =  [kGADSimulatorID]
        interstitialAd.delegate = self
        
        let concurrentQueue = DispatchQueue(label: "interstitial", attributes: .concurrent)
        concurrentQueue.sync {
            self.interstitialAd.load(request)
        }
    }
    
    func presentInterlude() {
        if (interstitialAd.isReady){
            interstitialAd.present(fromRootViewController: self)
            delayOneMinute {
                self.cycleInterstitialAd()
            }
        }else{
            NSLog("ad interstitial not loaded, so not presented")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let account: [String: String] = ["username": "client1", "password": "password"]
        UserDefaults(suiteName: "group.FreedomVPN")?.setValuesForKeys(account)
        
        navigationItem.title = NSLocalizedString("homeNaviBarText", comment: "")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "devices"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(HomeViewController.showDevices(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "settings"), style: .plain, target: self, action: #selector(HomeViewController.showSettings(sender:)))
        
        
        let vpnButton = VPNButton(
            frame:CGRect(
                x: view.center.x - 50,
                y: 80,
                width: 100,
                height: 100)
        )
        view.addSubview(vpnButton)
        
        cycleInterstitialAd()
        
        bannerView = GADBannerView(adSize: kGADAdSizeMediumRectangle)
        bannerView.delegate = self
        bannerView.adUnitID = "ca-app-pub-9174125730777485/5675800451"
        bannerView.rootViewController = self
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID]
        view.addSubview(bannerView)
        bannerView.snp.makeConstraints { (make) in
            make.top.equalTo(vpnButton.snp.bottom).offset(15)
            make.centerX.equalTo(view)
        }
        
        let concurrentQueue = DispatchQueue(label: "banner", attributes: .concurrent)
        concurrentQueue.sync {
            self.bannerView.load(request)
        }

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 5
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.itemSize = CGSize(width: 80, height: 100);
        flowLayout.scrollDirection = .vertical
        flowLayout.sectionInset =
            UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        collectView = UICollectionView(frame:
            CGRect(
                x: 0,
                y: view.frame.height - 200,
                width: view.frame.width,
                height: 200),
           collectionViewLayout: flowLayout)
        
        collectView.collectionViewLayout = flowLayout
        collectView.allowsMultipleSelection = false
        collectView.backgroundColor = .white
        collectView.register(ServerCollectionCell.classForCoder(),
                             forCellWithReuseIdentifier: collectionViewIdentifier)
        collectView.delegate = self
        collectView.dataSource = self
        view.addSubview(collectView)
        
        fetchVPNServers()
    }
    
    func showDevices(sender: UIBarButtonItem){
        navigationController?.pushViewController(DevicesViewController(), animated: true)
    }
    
    func showSettings(sender: UIBarButtonItem){
        navigationController?.pushViewController(WidgetSettingViewController(), animated: true)
    }
    
    func connectVPN(sender: UIButton){
        VPNManager.sharedVPNManager.saveAndConnect()
    }
    
    func fetchVPNServers(){
        hub = MBProgressHUD.showAdded(to: (navigationController?.view)!, animated: true)
        hub.center = view.center
        hub.show(animated: true)
        
        Alamofire.request(FreeVPN.Router.getServer()).validate().responseCollection { [weak self]
            (response: DataResponse<[Server]>) in
            if let result = response.result.value {
                self?.servers = result
                guard (self?.servers.count)! > 0 else {
                    return
                }
                let server = (self?.servers[0])!
                
                let vpnInfo: [String: String] = ["ip": server.ip, "remote_id": server.remote_id]
                UserDefaults(suiteName: "group.FreedomVPN")?.setValuesForKeys(vpnInfo)
                self?.collectView.reloadData()
                self?.collectView.setNeedsLayout()
                self?.collectView.layoutIfNeeded()
                self?.collectView.selectItem(at: IndexPath(index: 0), animated: false, scrollPosition: UICollectionViewScrollPosition(rawValue: 0))
                self?.hub.hide(animated: true)
            }
        }
    }
}


extension HomeViewController: GADBannerViewDelegate {

    func adViewWillLeaveApplication(_ bannerView: GADBannerView){

    }
    
    
}


extension HomeViewController: GADInterstitialDelegate {
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial){
        print("interstitialDidReceiveAd")
        presentInterlude()
    }
    
    func interstitialDidFail(toPresentScreen ad: GADInterstitial){
        print("interstitialDidFail")
        cycleInterstitialAd()
    }
    
    func interstitialWillLeaveApplication(_ ad: GADInterstitial){
        
    }
}

extension HomeViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(rated)
        
        if rated != "yes" && indexPath.row >= 2 {
            let locale = Locale.current
            
            let alert = UIAlertController(title: NSLocalizedString("alertTitle", comment: ""), message: NSLocalizedString("alertMsg", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            // add the actions (buttons)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "Ok"), style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                
                let path = URL(string: "https://itunes.apple.com/\(locale.regionCode!)/app/xiang-zi-youvpn-yi-kuan-liu/id1131521365?l=zh&ls=1&mt=8")
                UIApplication.shared.open(path!, options: [:], completionHandler: { (bool) in
                    KeyChainUtil.store("rated", value: "yes")
                    self.rated = "yes"
                })
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("no", comment: "No"), style: UIAlertActionStyle.cancel, handler: { (UIAlertAction) in
            }))
            // show the alert
            present(alert, animated: true, completion: nil)
        }else{
            let server = servers[indexPath.row]
            let vpnInfo: [String: String] = ["ip": server.ip, "remote_id": server.remote_id, "country": server.country, "country_cn": server.country_cn]    
            UserDefaults(suiteName: "group.FreedomVPN")?.setValuesForKeys(vpnInfo)
            
            let cell = collectView.cellForItem(at: indexPath)
            cell?.layer.borderColor = UIColor.darkGray.cgColor
            cell?.layer.borderWidth = 2
            cell?.layer.cornerRadius = 5
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.clear.cgColor
        cell?.layer.borderWidth = 2
        cell?.layer.cornerRadius = 5
    }
}


extension HomeViewController: UICollectionViewDataSource{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return servers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewIdentifier, for: indexPath) as! ServerCollectionCell
        cell.server = servers[indexPath.row]
        return cell
    }
}
