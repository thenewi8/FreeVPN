//
//  VPNButton.swift
//  HideMyAssVPN
//
//  Created by zhou ligang on 22/11/2016.
//  Copyright © 2016 zhouligang. All rights reserved.
//

import UIKit
import NetworkExtension

// dispatch_queue on main can interapt current animation
// on others can not

func delay(seconds: Double, complete: @escaping ()->()){
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10000)){
        complete()
    }
}

func delay1(seconds: Double, complete: @escaping ()->()){
    DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(5000)){
        complete()
    }
}


open class VPNButton: UIView {

    let lineWidth: CGFloat = 5.0
    
    var ovalShapeLayer: CAShapeLayer = CAShapeLayer()
    
    let manager = NEVPNManager.shared()
    var button: UIButton = {
        let btn = UIButton()
        return btn
    }()
    
    open var btnColor: UIColor = UIColor.brown {
        didSet{
            button.backgroundColor = btnColor
        }
    }
    
    open var titleSize: CGFloat = 14.0 {
        didSet{
            let attributedString = NSAttributedString(string: title, attributes: [
                NSFontAttributeName: UIFont.systemFont(ofSize: titleSize),
                NSForegroundColorAttributeName: UIColor.black,
                kCTUnderlineStyleAttributeName as String: NSUnderlineStyle.styleSingle.rawValue
                ])
            button.setAttributedTitle(attributedString, for: .normal)
        }
    }
    
    open var title: String = "" {
        didSet {
            let attributedString = NSAttributedString(string: title, attributes: [
                NSFontAttributeName: UIFont.systemFont(ofSize: titleSize),
                NSForegroundColorAttributeName: UIColor.black,
                kCTUnderlineStyleAttributeName as String: NSUnderlineStyle.styleSingle.rawValue
                ])
            button.setAttributedTitle(attributedString, for: .normal)
        }
    }
    
    var animationGroup: CAAnimationGroup = {
        let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
        strokeStartAnimation.fromValue = -0.5
        strokeStartAnimation.toValue = 1.0
        
        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = 0.0
        strokeEndAnimation.toValue = 1
        
        let strokeAnimationGroup = CAAnimationGroup()
        strokeAnimationGroup.duration = 1.5
        strokeAnimationGroup.repeatCount = 5.0
        strokeAnimationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
        return strokeAnimationGroup
    }()
    
    override public init(frame: CGRect){
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(VPNButton.vpnStatusChangeNotification), name: Notification.Name.NEVPNStatusDidChange, object: nil)
        
        setCurrentTitle()
    }
    
    open func setCurrentTitle(){
        manager.loadFromPreferences {[weak self] (error) in
            guard error == nil else {
                print("error: \(error)")
                self?.title = NSLocalizedString("Disconnected", comment: "Disconnected")
                return
            }
            let status = (self?.manager.connection.status)!
            
            switch status {
            case .connected:
                self?.title = NSLocalizedString("Connected", comment: "Connected")
            case .disconnected:
                self?.title = NSLocalizedString("Disconnected", comment: "Disconnected")
            case .disconnecting:
                self?.title = NSLocalizedString("Disconnecting", comment: "Disconnecting")
            case .connecting:
                self?.title = NSLocalizedString("Connecting", comment: "Connecting")
            default:
                self?.title = NSLocalizedString("Disconnected", comment: "Disconnected")
            }

        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func didMoveToWindow() {
        print("move to window")
    }
    
    override open func didMoveToSuperview() {
        print("move to superview")
//        addSubview(button)
    }
    
    override open func layoutSubviews() {
        let minLen = bounds.size.width > bounds.size.height ? bounds.size.height : bounds.size.width
        let btnlen = minLen - 5
        
        button.frame = CGRect(
            x: (bounds.size.width-btnlen)/2,
            y: (bounds.size.height-btnlen)/2,
            width: btnlen,
            height: btnlen)
        button.layer.cornerRadius = btnlen/2
        button.titleLabel?.textColor = .red
        button.backgroundColor = UIColor.brown
        button.addTarget(self,
                         action: #selector(VPNButton.startAnimation(sender:)),
                         for: .touchUpInside)
        addSubview(button)
        
        ovalShapeLayer.strokeColor = UIColor.white.cgColor
        ovalShapeLayer.fillColor = UIColor.clear.cgColor
        ovalShapeLayer.lineWidth = lineWidth
        ovalShapeLayer.lineDashPattern = [2, 3]
        ovalShapeLayer.path = nil
        layer.addSublayer(ovalShapeLayer)
    }

    @objc fileprivate func startAnimation(sender: UIButton) {
        
//        VPNManager.sharedVPNManager.saveAndConnect()
        VPNManager.sharedVPNManager.toggle()
        
        ovalShapeLayer.path = UIBezierPath(ovalIn: button.frame).cgPath
        ovalShapeLayer.add(animationGroup, forKey: "oval")
        delay(seconds: 2){
            self.ovalShapeLayer.path = nil
        }
     }
}


extension VPNButton {
    
    // to handler vpn status change
    func vpnStatusChangeNotification(){
        
        manager.loadFromPreferences { [weak self](error) in
            guard error == nil else {
                print()
                return
            }
            let status = (self?.manager.connection.status)!
            switch status {
            case .connected:
                self?.btnColor = .red
                self?.title = NSLocalizedString("Connected", comment: "Connected")
                self?.ovalShapeLayer.path = nil
            case .disconnected:
                self?.btnColor = .brown
                self?.title = NSLocalizedString("Disconnected", comment: "Disconnected")
                self?.ovalShapeLayer.path = nil
            case .disconnecting:
                self?.btnColor = .darkGray
                self?.title = NSLocalizedString("Disconnecting", comment: "Disconnecting")
                self?.ovalShapeLayer.path = UIBezierPath(ovalIn: (self?.button.frame)!).cgPath
            case .connecting:
                self?.btnColor = .darkGray
                self?.title = NSLocalizedString("Connecting", comment: "Connecting")
                self?.ovalShapeLayer.path = UIBezierPath(ovalIn: (self?.button.frame)!).cgPath
            default:
                self?.btnColor = .brown
                self?.title = NSLocalizedString("Connecting", comment: "Connecting")
                self?.ovalShapeLayer.path = nil
            }
        }
    }
}
