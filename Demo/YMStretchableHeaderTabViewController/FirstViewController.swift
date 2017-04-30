//
//  FirstViewController.swift
//  YMStretchableHeaderTabViewController
//
//  Created by Zhang Yuanming on 4/30/17.
//  Copyright © 2017 None. All rights reserved.
//

import UIKit

class FirstViewController: SegmentedViewController {

    let tags: [String] = ["tag1", "tag2", "tag3", "tag4", "tag5", "tag6", "tag7"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.


        var test: [(title: SegmentedControl.SegmentedItem, controller: UIViewController)] = []
        for tagName in tags {
            test.append((.init(value: tagName), SampleDataViewController()))
        }
        setControllersForSegments(contents: test)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

