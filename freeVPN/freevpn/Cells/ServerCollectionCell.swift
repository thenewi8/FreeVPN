//
//  ServerCollectionCellCollectionViewCell.swift
//  HideMyAssVPN
//
//  Created by zhou ligang on 28/11/2016.
//  Copyright © 2016 zhouligang. All rights reserved.
//

import UIKit
import SnapKit

class ServerCollectionCell: UICollectionViewCell {
    
    var server: Server? = nil {
        didSet{
            flagImageView.image = UIImage(named: (server?.code)!)
            let pre = NSLocale.preferredLanguages[0]
            if pre.contains("zh") {
                countryLabel.text = server?.country_cn
            }else{
                countryLabel.text = server?.country
            }
        }
    }

    var flagImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    var countryLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .red
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        addSubview(flagImageView)
        flagImageView.snp.makeConstraints { (make) in
            make.top.equalTo(self).offset(5)
            make.centerX.equalTo(self)
            make.width.equalTo(self)
            make.height.equalTo(60)
        }
        
        addSubview(countryLabel)
        countryLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.bottom.equalTo(self).offset(-5)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        
    }
}
