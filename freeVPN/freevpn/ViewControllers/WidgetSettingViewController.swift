//
//  WidgetSettingViewController.swift
//  freevpn
//
//  Created by zhou ligang on 18/01/2017.
//  Copyright © 2017 ligulfzhou. All rights reserved.
//

import UIKit

class WidgetSettingViewController: UIViewController {
    
    var tableViewData = [["setting1.jpgsetting1.jpgsetting1.jpg", "setting1.jpg"], ["setting1.jpgsetting1.jpgsetting1.jpg", "setting1.jpg"], ["setting1.jpgsetting1.jpgsetting1.jpg", "setting1.jpg"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let image = UIImage.imageWithText(drawText: "000", inImageName: "setting1.jpg", atPoint: CGPoint(x: 100.0, y: 100.0))
        let imageview = UIImageView(image: image)
        imageview.frame = view.bounds
        view.addSubview(imageview)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textToImage(drawText text: NSString, inImage image: UIImage, atPoint point: CGPoint) -> UIImage {
        let textColor = UIColor.red
//        let textFont = UIFont(name: "Helvetica Bold", size: 20)!
        let textFont = UIFont.systemFont(ofSize: 20)
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ] as [String : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        let rect = CGRect(origin: point, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
}
