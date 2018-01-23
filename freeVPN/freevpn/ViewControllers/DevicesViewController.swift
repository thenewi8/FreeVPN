//
//  DevicesViewController.swift
//  freevpn
//
//  Created by zhou ligang on 01/12/2016.
//  Copyright © 2016 ligulfzhou. All rights reserved.
//

import UIKit

class DevicesViewController: UIViewController {

    var tableView: UITableView!
    var images: [String] = ["mac", "android"]
    var titles: [String] = ["Mac", "Android"]
    var details = NSLocalizedString("See You 2017", comment: "See You 2017")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: view.frame, style: .plain)
        tableView.allowsSelection = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension DevicesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "identifier")
        cell.imageView?.image = UIImage(named: images[indexPath.row])
        cell.textLabel?.text = titles[indexPath.row]
        cell.detailTextLabel?.text = details
        return cell
    }
}

extension DevicesViewController: UITableViewDelegate {
    

}
