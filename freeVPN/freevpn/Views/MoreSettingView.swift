//
//  MoreSettingView.swift
//  freevpn
//
//  Created by ligulfzhou on 6/26/16.
//  Copyright © 2016 ligulfzhou. All rights reserved.
//

import UIKit

class MoreSettingView: UIView {
    
    var moreSettingText: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        moreSettingText = UILabel(frame: frame)
        moreSettingText.text = "自己动手，丰衣足食"
        moreSettingText.center = self.center
        moreSettingText.textAlignment = .Center
        self.addSubview(moreSettingText)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
