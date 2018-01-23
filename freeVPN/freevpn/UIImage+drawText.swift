//
//  UIImage+drawText.swift
//  freevpn
//
//  Created by zhou ligang on 18/01/2017.
//  Copyright © 2017 ligulfzhou. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
     static func imageWithText(drawText text: NSString, inImageName imageName: String, atPoint point: CGPoint) -> UIImage {
        let image = UIImage(named: imageName)
        let textColor = UIColor.red
//        let textFont = UIFont(name: "Helvetica Bold", size: 20)!
        let textFont = UIFont.systemFont(ofSize: 30)
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions((image?.size)!, false, scale)
        
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ] as [String : Any]
        image?.draw(in: CGRect(origin: CGPoint.zero, size: (image?.size)!))
        
        let rect = CGRect(origin: point, size: (image?.size)!)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
