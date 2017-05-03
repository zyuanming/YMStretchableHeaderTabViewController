//
//  SampleHeaderView.swift
//  YMStretchableHeaderTabViewController
//
//  Created by Zhang Yuanming on 5/2/17.
//  Copyright © 2017 None. All rights reserved.
//

import UIKit

class SampleHeaderView: StretchableHeaderView, StretchableHeaderViewDelegate, UIGestureRecognizerDelegate {

    lazy var button: UIButton = {
        let button = UIButton(type: .contactAdd)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        addConstraints([
            NSLayoutConstraint(item: button, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: button, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0)
        ])

        isUserInteractionEnabled = true
        let tagGesture = UITapGestureRecognizer(target: self, action: #selector(handleTagGesture(_:)))
        tagGesture.delegate = self
        addGestureRecognizer(tagGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func interactiveSubviews(in headerView: StretchableHeaderView) -> [UIView] {
        return [button, self]
    }

    func handleTagGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        print("tag.....")
    }

}


