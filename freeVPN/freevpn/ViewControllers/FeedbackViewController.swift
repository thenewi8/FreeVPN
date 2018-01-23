//
//  FeedbackViewController.swift
//  freevpn
//
//  Created by ligulfzhou on 4/1/16.
//  Copyright © 2016 ligulfzhou. All rights reserved.
//

import UIKit
import Alamofire

class FeedbackViewController: UITableViewController
//, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource
{

    let cellIdentifier = "feedbackTableCellIdentifier"
    var feedbacks: [Feedback]?
//    var feedbackTable: UITableView!
    
    var rightNavBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        feedbacks = []
        setUpView()
        fetchFeedbacks()
    }
    
    func fetchFeedbacks(){
        Alamofire.request(FreeVPN.Router.feedback(1, 20)).validate().responseCollection {
            (response: Response<[Feedback], NSError>) in
            guard response.result.error == nil else {return}
            self.feedbacks = []
            self.feedbacks = response.result.value
            self.tableView.reloadData()
            
            self.tableView.setNeedsLayout()
            self.tableView.layoutIfNeeded()
            self.refreshControl?.endRefreshing()
        }
    }
    func setUpView(){
        
        self.navigationItem.title = "反馈"
        rightNavBtn = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(FeedbackViewController.addFeedback))
        self.navigationItem.rightBarButtonItem = rightNavBtn
        
        self.refreshControl = UIRefreshControl()
//        self.refreshControl?.backgroundColor = UIColor.purpleColor()
        self.refreshControl?.tintColor = UIColor.blueColor()
        self.refreshControl?.addTarget(self, action: #selector(FeedbackViewController.fetchFeedbacks), forControlEvents: .ValueChanged)
        
        self.tableView = UITableView()
        self.tableView.registerClass(FeedbackTableCell.self, forCellReuseIdentifier: cellIdentifier)
        self.tableView.frame = view.frame
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.estimatedRowHeight = 300
        self.tableView.rowHeight = UITableViewAutomaticDimension

//        feedbackTable.emptyDataSetSource = self
//        feedbackTable.emptyDataSetDelegate = self
//        view.addSubview(feedbackTable)
    }
    
    //MARK: tableview datasource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (feedbacks?.count)!
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! FeedbackTableCell
        let myfeedback = feedbacks![(indexPath as NSIndexPath).row]
        cell.setqq(myfeedback.qq, andName: myfeedback.name, andFeedback: myfeedback.feedback)
        return cell
    }
    
    func addFeedback(){
        let addFeedbackVC = AddFeedbackViewController()

        addFeedbackVC.modalTransitionStyle = .CrossDissolve
        addFeedbackVC.modalPresentationStyle = .CurrentContext
        self.parentViewController!.presentViewController(addFeedbackVC, animated: true, completion: nil)
    }
    //MARK: tableview delegate
    
    //MARK: empty datasource
    
    //MARK: empty delegate

}
