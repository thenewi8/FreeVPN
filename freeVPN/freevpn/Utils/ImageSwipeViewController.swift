//
//  ImageSwipeViewController.swift
//  freevpn
//
//  Created by ligulfzhou on 7/4/16.
//  Copyright © 2016 ligulfzhou. All rights reserved.
//
//  in viewDidLoad, add all subviews to view, not set where did the specific subview in the view
//  but in viewDidLayoutSubviews,
// http://stackoverflow.com/questions/32778549/swift-how-to-apply-resize-images-inside-scrollview
//

import UIKit

class ImageSwipeViewController: UIViewController, UIScrollViewDelegate {
    
    var imgIdx: Int = 0
    var imgNameList: [String] = []
    var imgUrlList: [String] = []      // 暂时还不需要做兼容，只需要imgNameList就行了
    var imageViews: [UIImageView] = []
//    var imageView: UIImageView!
    var scrollView: UIScrollView!
    var pageControl: UIPageControl!
    
    var swipeLeftGesture: UISwipeGestureRecognizer!
    var swipeRightGesture: UISwipeGestureRecognizer!
    var doubelTapGesture: UITapGestureRecognizer!
    
    override func viewDidLoad(){

//        imageView = UIImageView()
//        imageView.image = UIImage(named: imgNameList[imgIdx])
        
        scrollView = UIScrollView(frame: view.frame)
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.whiteColor()
//        scrollView.addSubview(imageView)
        view.addSubview(scrollView)
        configurePageControl()
        
        for imageName in imgNameList{
            let imgV = UIImageView(image: UIImage(named: imageName))
            scrollView.addSubview(imgV)
            imageViews.append(imgV)
        }
        
        doubelTapGesture = UITapGestureRecognizer(target: self, action: #selector(ImageSwipeViewController.closeModal(_:)))
        doubelTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubelTapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for (index, imageView) in imageViews.enumerate(){
            imageView.frame = CGRect(x: CGFloat(index) * scrollView.frame.size.width, y: 0, width: scrollView.frame.size.width, height: scrollView.frame.size.height - 49 - 50)
            imageView.contentMode = .ScaleAspectFit
        }
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width * CGFloat(imgNameList.count), height: scrollView.frame.size.height)
    }
    
    func configurePageControl(){
        pageControl = UIPageControl()
        pageControl.numberOfPages = imgNameList.count
        pageControl.currentPage = imgIdx
        pageControl.tintColor = UIColor.blueColor()
        pageControl.pageIndicatorTintColor = UIColor.redColor()
        pageControl.currentPageIndicatorTintColor = UIColor.whiteColor()
        view.addSubview(pageControl)
    }
    
    func closeModal(sender: UITapGestureRecognizer){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
