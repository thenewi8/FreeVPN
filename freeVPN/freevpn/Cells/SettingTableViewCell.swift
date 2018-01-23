//
//  SettingTableViewCell.swift
//  freevpn
//
//  Created by zhou ligang on 18/01/2017.
//  Copyright © 2017 ligulfzhou. All rights reserved.
//

import UIKit
import SnapKit

class SettingTableViewCell: UITableViewCell {
    
    var imgView: UIImageView!
    var textMsg: String!
    var imageName: String? = nil {
        didSet {
            
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
