//
//  SampleDataViewController.swift
//  YMStretchableHeaderTabViewController
//
//  Created by Zhang Yuanming on 4/30/17.
//  Copyright © 2017 None. All rights reserved.
//

import UIKit

class SampleDataViewController: UITableViewController {

    var datas: [String] = ["hello", "hi", "very good", "yes.", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten...", "elevent", "bgqwwwwwiu1`ss1 ", "123yeo", "you are", "i am", "hello word", "hi"]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")

        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return datas.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        let text = datas[indexPath.row]
        cell.textLabel?.text = text

        return cell
    }



}