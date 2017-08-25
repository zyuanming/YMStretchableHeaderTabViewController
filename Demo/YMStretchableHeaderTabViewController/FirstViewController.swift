//
//  FirstViewController.swift
//  YMStretchableHeaderTabViewController
//
//  Created by Zhang Yuanming on 4/30/17.
//  Copyright © 2017 None. All rights reserved.
//

import UIKit

class FirstViewController: SegmentedViewController, UIGestureRecognizerDelegate {

    let tags: [String] = ["tag1", "tag2", "tag3", "tag4", "tag5", "tag6", "tag7"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.


        var test: [(title: SegmentedControl.SegmentedItem, controller: UIViewController)] = []
        for (index, tagName) in tags.enumerated() {
            let vc = SampleDataViewController(style: .grouped)

            if index == 0 {
                vc.datas = ["hello", "hi", "very good", "yes.", "one", "two",
                            "three", "four", "five", "six", "seven", "eight",
                            "nine", "ten...", "elevent", "bgqwwwwwiu1`ss1 ",
                            "123yeo", "you are", "i am", "hello word", "hi"].map{ "\($0)_\(index + 1)"}
            } else if index == 1 {
                vc.datas = ["hello", "hi", "very good", "yes.", "one", "two",
                            "three", "four", "five"].map{ "\($0)_\(index + 1)"}
            } else {
                let datas = ["hello", "hi", "very good", "yes.", "one", "two",
                             "three", "four", "five", "six", "seven", "eight",
                             "nine", "ten...", "elevent", "bgqwwwwwiu1`ss1 ",
                             "123yeo", "you are", "i am", "hello word", "hi"].map{ "\($0)_\(index + 1)"}
                let randomNum = arc4random_uniform(UInt32(datas.count))
                vc.datas = Array(datas.prefix(upTo: Int(randomNum)))
            }
            test.append((.init(value: tagName), vc))
        }
        setControllersForSegments(contents: test)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func addHeaderView() {
        let sampleHeaderView = SampleHeaderView()
        sampleHeaderView.backgroundColor = UIColor.red
        headerView = sampleHeaderView
        view.addSubview(sampleHeaderView)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        pan.delegate = self
        sampleHeaderView.addGestureRecognizer(pan)
    }

    func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        let selectedViewController = segmentedViewController[selectedIndex]
        guard let currentScrollView = scrollViewWithSubViewController(viewController: selectedViewController) else { return }
        // 偏移计算
        let point = pan.translation(in: headerView!)
        let contentOffset = currentScrollView.contentOffset
        let border = -headerView!.maximumOfHeight - segmentedControlHeight
        let offsety = contentOffset.y - point.y * (1/contentOffset.y * border * 0.8)
        currentScrollView.contentOffset = CGPoint(x: contentOffset.x, y: offsety)

        if (pan.state == .ended || pan.state == .failed) {
            if contentOffset.y <= border {
                // 如果处于刷新
                // 模拟弹回效果
                UIView.animate(withDuration: 0.35, animations: {
                    currentScrollView.contentOffset = CGPoint(x: contentOffset.x, y: border)
                    self.view.layoutIfNeeded()
                })

            }
        }

        // 清零防止偏移累计

        pan.setTranslation(CGPoint.zero, in: headerView)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let point = pan.translation(in: headerView!)
            if fabs(point.y) <= fabs(point.x) {
                return false
            }
        }

        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }

}

