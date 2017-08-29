
import UIKit

protocol SegmentedViewControllerDelegate: class {
    func didScrollToPageAtIndex(_ index: Int)
}

@objc protocol StretchableSubViewControllerViewSource {
    @objc func stretchableSubViewInSubViewController(viewController: UIViewController) -> UIScrollView
}


class SegmentedViewController: UIViewController {

    var segmentedControl = SegmentedControl()
    weak var delegate: SegmentedViewControllerDelegate?
    var headerView: StretchableHeaderView?
    var scrollView = UIScrollView()
    var containerView = UIView()
    var segmentedViewController: [UIViewController] = []
    fileprivate var segmentedBackgroundViews: [UIView] = []
    fileprivate var _selectedIndex = 0
    fileprivate var lastSegmentControlFrame: CGRect = CGRect.zero
    
    var pageTurning: Bool {
        get {return scrollView.isTracking}
    }
    
    var selectedIndex: Int {
        get { return _selectedIndex }
        set {
            showSelectedViewController(at: newValue, animated: true)
            _selectedIndex = newValue
            lastSegmentControlFrame = segmentedControl.frame
        }
    }
    
    let segmentedControlBackgroundColor = UIColor.white
    
    var segmentedControlHeight: CGFloat = 40 {
        willSet { _segmentedControlHeightConstrait?.constant = newValue }
    }
    
    fileprivate var _segmentedControlHeightConstrait: NSLayoutConstraint?


    // MARK: - LifeCycle
    
    deinit {
        scrollView.delegate = nil
        clearObserver()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        automaticallyAdjustsScrollViewInsets = false
        configureSegmentedController()
        addPrivateViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }


    // MARK: -

    fileprivate func clearObserver() {
        for vc in segmentedViewController {
            if vc.parent != nil {
                if let targetScrollView = self.scrollViewWithSubViewController(viewController: vc) {
                    targetScrollView.removeObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset))
                }
            }
        }
    }

    func layoutHeaderViewAndTabBar() {
        guard let headerView = headerView,
            0 <= selectedIndex, selectedIndex < segmentedViewController.count, !pageTurning else { return }

        let selectedViewController = segmentedViewController[selectedIndex]
        if let scrollView = scrollViewWithSubViewController(viewController: selectedViewController) {
            var headerViewHeight = headerView.maximumOfHeight - (scrollView.contentOffset.y + scrollView.contentInset.top);
            headerViewHeight = max(headerViewHeight, headerView.minimumOfHeight);
            if (headerView.bounces == false) {
                headerViewHeight = min(headerViewHeight, headerView.maximumOfHeight);
            }

            let realHeight = headerViewHeight + self.scrollView.contentInset.top;
            if (realHeight < headerView.maximumOfHeight + self.scrollView.contentInset.top) {
                let originY = realHeight - headerView.maximumOfHeight - self.scrollView.contentInset.top
                headerView.frame = CGRect(x: 0, y: originY, width: headerView.frame.size.width, height: headerView.maximumOfHeight);
            } else {
                headerView.frame = CGRect(x: 0, y: 0, width: headerView.frame.size.width, height: realHeight);
            }

            scrollView.scrollIndicatorInsets = UIEdgeInsets(top: segmentedControl.frame.maxY - self.scrollView.contentInset.top, left: 0, bottom: 49, right: 0)
        } else {
            headerView.frame = CGRect(origin: headerView.frame.origin, size: CGSize(width: headerView.frame.width, height: headerView.maximumOfHeight + self.scrollView.contentInset.top))
        }

        let segmentControllY = headerView.frame.maxY
        segmentedControl.frame = CGRect(origin: CGPoint(x: 0, y: segmentControllY), size: CGSize(width: self.view.frame.width, height: segmentedControlHeight))
    }

    func scrollViewWithSubViewController(viewController: UIViewController) -> UIScrollView? {
        if viewController.responds(to: #selector(StretchableSubViewControllerViewSource.stretchableSubViewInSubViewController(viewController:))) {
            return (viewController as! StretchableSubViewControllerViewSource).stretchableSubViewInSubViewController(viewController: self)
        } else if let scrollView = viewController.view as? UIScrollView {
            return scrollView
        } else {
            return nil
        }
    }

    func setControllersForSegments(contents: [(title: SegmentedControl.SegmentedItem, controller: UIViewController)]) {
        clearObserver()
        headerView?.frame = CGRect(x: 0, y: headerView!.frame.minY, width: self.view.bounds.width, height: headerView!.maximumOfHeight + scrollView.contentInset.top)
        let segmentControllY = headerView!.frame.maxY
        segmentedControl.frame = CGRect(origin: CGPoint(x: 0, y: segmentControllY), size: CGSize(width: self.view.frame.width, height: segmentedControlHeight))

        segmentedViewController = contents.map({$0.1})
        segmentedControl.items = contents.map({$0.0})
        addContainerView()
        _selectedIndex = 0
        segmentedControl.selectedSegmentIndex = selectedIndex
        showSelectedPage()
    }
    
    fileprivate func addPrivateViews() {
        scrollView.frame = self.view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        view.addSubview(scrollView)

        view.addSubview(segmentedControl)
        addHeaderView()
    }

    func addHeaderView() {
        headerView = StretchableHeaderView()
        headerView?.backgroundColor = UIColor.red
        view.addSubview(headerView!)
    }
    
    fileprivate func addContainerView() {
        containerView.removeFromSuperview()
        containerView.subviews.forEach { $0.removeFromSuperview() }
        segmentedBackgroundViews.removeAll()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(containerView)
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[container]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["container": containerView]))
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[container]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["container": containerView]))
        view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .height, relatedBy: .equal, toItem: scrollView, attribute: .height, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: containerView, attribute: .width, relatedBy: .equal, toItem: scrollView, attribute: .width, multiplier: CGFloat(segmentedViewController.count), constant: 0))
        
        var horizontalConstraintsFormat = "H:|"
        var viewsDict: [String: UIView] = ["ancestorView": scrollView]
        for index in 0..<segmentedViewController.count {
            let pageBackgroundView = UIView()
            segmentedBackgroundViews.append(pageBackgroundView)
            pageBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(pageBackgroundView)
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subview]|", options: [], metrics: nil, views: ["subview": pageBackgroundView]))
            
            viewsDict["v\(index)"] = pageBackgroundView
            horizontalConstraintsFormat += "[v\(index)(==ancestorView)]"
        }
        
        horizontalConstraintsFormat += "|"
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: horizontalConstraintsFormat, options: [], metrics: nil, views: viewsDict))

    }
    
    fileprivate func configureSegmentedController() {
        segmentedControl.segmentNormalColor = UIColor.lightGray
        segmentedControl.tintColor = UIColor.blue
        segmentedControl.backgroundColor = segmentedControlBackgroundColor
        segmentedControl.normalFont = UIFont.systemFont(ofSize: 15)
        segmentedControl.selectedFont = UIFont.systemFont(ofSize: 15)
        segmentedControl.addTarget(self, action: #selector(SegmentedViewController.onSegmentedControlValueChanged(_:)), for: .valueChanged)
    }

    func showSelectedPage() {
        loadSubControllerIfNeeded()
        scrollToPageAtIndex(selectedIndex)
        let viewController = segmentedViewController[selectedIndex]
        viewController.beginAppearanceTransition(true, animated: false)
        viewController.endAppearanceTransition()
    }
    
    func loadSubControllerIfNeeded(_ index: Int? = nil) {
        assert(segmentedControl.numberOfSegments == segmentedViewController.count, "segmentedControl's count must be equal to subviewcontroller's count")
        
        let currentIndex = index ?? segmentedControl.selectedSegmentIndex
        if 0 <= currentIndex && currentIndex < segmentedViewController.count {
            let viewController = segmentedViewController[currentIndex]
            if viewController.parent == nil {
                addChildViewController(viewController)
                let backgroundView = segmentedBackgroundViews[currentIndex]
                backgroundView.addSubview(viewController.view)
                viewController.view.translatesAutoresizingMaskIntoConstraints = false
                backgroundView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[v]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["v": viewController.view]))
                backgroundView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["v": viewController.view]))
                viewController.didMove(toParentViewController: self)

                if let scrollView = self.scrollViewWithSubViewController(viewController: viewController) {
                    viewController.view.layoutIfNeeded()
                    if #available(iOS 11.0, *) {
                        scrollView.contentInsetAdjustmentBehavior = .never
                    }
                    let headerOffset = headerView!.maximumOfHeight
                    scrollView.contentOffset = CGPoint(x: 0, y: -(headerView!.frame.maxY + segmentedControlHeight))
                    scrollView.contentInset = UIEdgeInsets(top: headerOffset + segmentedControlHeight, left: 0, bottom: 84, right: 0)
                    scrollView.addObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset), options: [.new], context: nil)
                }
            }
            layoutSubViewControllerToSelectedViewController()
        }
    }

    func layoutUI() {
        headerView?.frame = CGRect(x: 0, y: headerView!.frame.minY, width: self.view.bounds.width, height: headerView!.maximumOfHeight + scrollView.contentInset.top)
        let segmentControllY = headerView!.frame.maxY
        segmentedControl.frame = CGRect(origin: CGPoint(x: 0, y: segmentControllY), size: CGSize(width: self.view.frame.width, height: segmentedControlHeight))

        for vc in segmentedViewController {
            if vc.parent != nil {
                if let scrollView = self.scrollViewWithSubViewController(viewController: vc) {
                    let headerOffset = headerView!.maximumOfHeight
                    scrollView.contentOffset = CGPoint(x: 0, y: -(headerView!.frame.maxY + segmentedControlHeight))
                    scrollView.contentInset = UIEdgeInsets(top: headerOffset + segmentedControlHeight, left: 0, bottom: 84, right: 0)
                }
            }
        }
    }

    func layoutSubViewControllerToSelectedViewController() {
        let selectedViewController = segmentedViewController[selectedIndex]
        for vc in segmentedViewController {
            if vc == selectedViewController {
                continue
            }

            if vc.parent != nil {
                if let targetScrollView = self.scrollViewWithSubViewController(viewController: vc) {

                    if !lastSegmentControlFrame.equalTo(segmentedControl.frame) {
                        targetScrollView.contentOffset = CGPoint(x: targetScrollView.contentOffset.x, y: -(segmentedControl.frame.maxY - self.scrollView.contentInset.top))
                    }
                }
            }
        }
    }

    func scrollToPageAtIndex(_ index: Int, animated: Bool = false) {
        guard 0 <= index && index < segmentedControl.numberOfSegments else { return }

        var scrollBounds = self.scrollView.bounds
        scrollBounds.origin = CGPoint(x: CGFloat(index) * self.scrollView.bounds.width, y: 0)

        let newIndex = index
        let oldIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)
        scrollView.setContentOffset(CGPoint(x: scrollView.bounds.width * CGFloat(index), y: 0), animated: false)
        let shiftX = newIndex > oldIndex ? scrollView.bounds.width : -scrollView.bounds.width

        if animated {

            let oldVC = segmentedViewController[oldIndex]
            let targetScrollView = self.scrollViewWithSubViewController(viewController: oldVC)
            targetScrollView?.showsVerticalScrollIndicator = false

            CATransaction.begin()
            CATransaction.setCompletionBlock {
                targetScrollView?.showsVerticalScrollIndicator = true
                self.delegate?.didScrollToPageAtIndex(index)
            }
            let oldViewFromValue = CGFloat(newIndex - oldIndex) * scrollView.bounds.width
            let oldViewToValue = CGFloat(newIndex - oldIndex - (newIndex > oldIndex ? 1 : -1)) * scrollView.bounds.width

            let animation = CABasicAnimation(keyPath: "transform.translation.x")
            animation.fromValue = NSNumber(value: Double(shiftX) as Double)
            animation.toValue = NSNumber(value: 0 as Double)
            animation.duration = 0.3
            animation.beginTime = 0.0
            animation.isRemovedOnCompletion = true

            segmentedViewController[newIndex].view.layer.add(animation, forKey: "shift")

            let animation2 = CABasicAnimation(keyPath: "transform.translation.x")
            animation2.fromValue = NSNumber(value: Double(oldViewFromValue) as Double)
            animation2.toValue = NSNumber(value: Double(oldViewToValue) as Double)
            animation2.duration = 0.3
            animation2.beginTime = 0.0
            animation2.isRemovedOnCompletion = true

            segmentedViewController[oldIndex].view.layer.add(animation2, forKey: "shift")
            CATransaction.commit()
        } else {
            self.delegate?.didScrollToPageAtIndex(index)
        }

    }



    func showSelectedViewController(at index: Int, animated: Bool) {
        guard 0 <= index && index < segmentedViewController.count else { return }

        if selectedIndex != index {
            segmentedControl.selectedSegmentIndex = index
            loadSubControllerIfNeeded()
            segmentedViewController[index].beginAppearanceTransition(true, animated: animated)
            segmentedViewController[index].endAppearanceTransition()
            segmentedViewController[selectedIndex].beginAppearanceTransition(false, animated: animated)
            segmentedViewController[selectedIndex].endAppearanceTransition()
            _selectedIndex = index
        }
    }


    // MARK: - SegmentedControl Action

    func onSegmentedControlValueChanged(_ sender: SegmentedControl) {
        let currentIndex = segmentedControl.selectedSegmentIndex
        selectedIndex = currentIndex
        scrollToPageAtIndex(currentIndex, animated: true)
    }

}


// MARK: - Observer

extension SegmentedViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        if pageTurning { return }
        let selectedViewController = segmentedViewController[selectedIndex]
        if let scrollView = self.scrollViewWithSubViewController(viewController: selectedViewController) {
            if let objectScrollView = object as? UIScrollView, scrollView != objectScrollView {
                return
            }
            if scrollView.isTracking {
                scrollView.showsVerticalScrollIndicator = true
            }
            self.layoutHeaderViewAndTabBar()
        }
    }
}


// MARK: - UIScrollViewDelegate

extension SegmentedViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x / scrollView.bounds.width
        let currentPageIndex = Int(offset + 0.5)
        if selectedIndex != currentPageIndex {
            selectedIndex = currentPageIndex
        }

        if offset == trunc(offset) {
            delegate?.didScrollToPageAtIndex(currentPageIndex)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.layoutSubViewControllerToSelectedViewController()
        let selectedViewController = segmentedViewController[selectedIndex]
        if let targetScrollView = self.scrollViewWithSubViewController(viewController: selectedViewController) {
            targetScrollView.showsVerticalScrollIndicator = false
        }
    }
}

extension UIViewController {
    var segmentedController: SegmentedViewController? {
        get {
            var parentController: UIViewController? = self
            while parentController != nil {
                if parentController is SegmentedViewController {
                    return parentController as? SegmentedViewController
                }
                parentController = parentController!.parent
            }
            return nil
        }
    }
}
