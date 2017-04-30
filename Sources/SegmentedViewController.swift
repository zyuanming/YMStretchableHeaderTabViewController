
import UIKit

@objc protocol SegmentedViewControllerDelegate: NSObjectProtocol {
    @objc optional func didScrollToPageAtIndex(_ index: Int)
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
    fileprivate var observerContext = UInt8()
    fileprivate var disableObserverScrollViewContentOffset = false
    fileprivate var _selectedIndex = 0
    
    var pageTurning: Bool {
        get {return disableObserverScrollViewContentOffset || scrollView.isTracking}
    }
    
    var selectedIndex: Int {
        get { return _selectedIndex }
        set { showSelectedViewController(at: newValue, animated: true) ; _selectedIndex = newValue }
    }
    
    let segmentedControlBackgroundColor = UIColor.white
    
    var segmentedControlHeight: CGFloat = 40 {
        willSet { _segmentedControlHeightConstrait?.constant = newValue }
    }
    
    fileprivate var _segmentedControlHeightConstrait: NSLayoutConstraint?


    // MARK: - LifeCycle
    
    deinit {
        /**
         *  `scrollView.superview`不为空，那肯定调用过`viewDidLoad`。`scrollView`必被`self`观察键`contentOffset`，可以安全移除。
         */
        if scrollView.superview != nil {
            scrollView.delegate = nil
            scrollView.removeObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset), context: &observerContext)
        }
        clearObserver()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        automaticallyAdjustsScrollViewInsets = false
        configureSegmentedController()
        addPrivateViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerView?.frame = CGRect(x: 0, y: headerView!.frame.minY, width: self.view.bounds.width, height: headerView!.maximumOfHeight + scrollView.contentInset.top)
        let segmentControllY = headerView!.frame.maxY
        segmentedControl.frame = CGRect(origin: CGPoint(x: 0, y: segmentControllY), size: CGSize(width: self.view.frame.width, height: segmentedControlHeight))
        disableObserverScrollViewContentOffset = true
        self.updateOffset()
        self.layoutHeaderViewAndTabBar()
        disableObserverScrollViewContentOffset = false
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
        scrollView.addObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset), options: [.new, .old], context: &observerContext)
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
    
    func loadSubControllerIfNeeded() {
        assert(segmentedControl.numberOfSegments == segmentedViewController.count, "segmentedControl's count must be equal to subviewcontroller's count")
        
        let currentIndex = segmentedControl.selectedSegmentIndex
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

                    let headerOffset = headerView!.maximumOfHeight
                    scrollView.contentOffset = CGPoint(x: 0, y: -(headerView!.frame.maxY + segmentedControlHeight))
                    scrollView.contentInset = UIEdgeInsets(top: headerOffset + segmentedControlHeight, left: 0, bottom: 84, right: 0)
                    scrollView.addObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset), options: [.new], context: nil)
                }
            }

            layoutSubViewControllerToSelectedViewController()
        }
    }

    func updateOffset() {
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
        guard selectedIndex >= 0 , selectedIndex < segmentedViewController.count else { return }
        let selectedViewController = segmentedViewController[selectedIndex]
        if let selectedScrollView = self.scrollViewWithSubViewController(viewController: selectedViewController) {
            for vc in segmentedViewController {
                if vc == selectedViewController {
                    continue
                }

                if vc.parent != nil {
                    if let targetScrollView = self.scrollViewWithSubViewController(viewController: vc) {
                        let relativePositionY = caculate(contentOffsetY: selectedScrollView.contentOffset.y, contentInsetTop: selectedScrollView.contentInset.top)
                        if relativePositionY > 0 {
                            targetScrollView.contentOffset = selectedScrollView.contentOffset
                        } else {
                            let targetRelativePositionY = caculate(contentOffsetY: targetScrollView.contentOffset.y, contentInsetTop: targetScrollView.contentInset.top)
                            if targetRelativePositionY > 0 {
                                targetScrollView.contentOffset = CGPoint(x: targetScrollView.contentOffset.x, y: -(segmentedControl.frame.maxY - self.scrollView.contentInset.top))
                            }
                        }
                    }
                }
            }
        }
    }


    func adjustOffset(from: Int, to: Int) {
        guard 0 <= from && from < segmentedViewController.count &&
            0 <= to && to < segmentedViewController.count else { return }

        let fromViewController = segmentedViewController[from]
        let toViewController = segmentedViewController[to]

        guard let fromScrollView = scrollViewWithSubViewController(viewController: fromViewController),
            let toScrollView = scrollViewWithSubViewController(viewController: toViewController) else { return }

        let relativePositionY = caculate(contentOffsetY: fromScrollView.contentOffset.y, contentInsetTop: fromScrollView.contentInset.top)
        if relativePositionY > 0 {
            toScrollView.contentOffset = fromScrollView.contentOffset
        } else {
            let targetRelativePositionY = caculate(contentOffsetY: toScrollView.contentOffset.y, contentInsetTop: toScrollView.contentInset.top)
            if targetRelativePositionY > 0 {
                toScrollView.contentOffset = CGPoint(x: toScrollView.contentOffset.x, y: -(segmentedControl.frame.maxY - self.scrollView.contentInset.top))
            }
        }
    }

    func caculate(contentOffsetY: CGFloat, contentInsetTop: CGFloat) -> CGFloat {
        return headerView!.maximumOfHeight - headerView!.minimumOfHeight - (contentOffsetY + contentInsetTop)
    }

    func scrollToPageAtIndex(_ index: Int, animated: Bool = false) {
        guard 0 <= index && index < segmentedControl.numberOfSegments else { return }

        var scrollBounds = self.scrollView.bounds
        scrollBounds.origin = CGPoint(x: CGFloat(index) * self.scrollView.bounds.width, y: 0)
        disableObserverScrollViewContentOffset = true

        let newIndex = index
        let oldIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)
        scrollView.setContentOffset(CGPoint(x: scrollView.bounds.width * CGFloat(index), y: 0), animated: false)
        let shiftX = newIndex > oldIndex ? scrollView.bounds.width : -scrollView.bounds.width

        if animated {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.disableObserverScrollViewContentOffset = false
                self.delegate?.didScrollToPageAtIndex?(index)
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
            self.disableObserverScrollViewContentOffset = false
            self.delegate?.didScrollToPageAtIndex?(index)
        }

    }



    func showSelectedViewController(at index: Int, animated: Bool) {
        guard 0 <= index && index < segmentedViewController.count else { return }

        if selectedIndex != index {
            segmentedControl.selectedSegmentIndex = index
            loadSubControllerIfNeeded()
            scrollToPageAtIndex(index, animated: animated)
            segmentedViewController[index].beginAppearanceTransition(true, animated: animated)
            segmentedViewController[index].endAppearanceTransition()
            segmentedViewController[selectedIndex].beginAppearanceTransition(false, animated: animated)
            segmentedViewController[selectedIndex].endAppearanceTransition()
            _selectedIndex = index
        }
    }


    // MARK: - SegmentedControl Action

    func onSegmentedControlValueChanged(_ sender: SegmentedControl) {
        selectedIndex = segmentedControl.selectedSegmentIndex
    }

}


// MARK: - Observer

extension SegmentedViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        if context == &observerContext {
            guard !disableObserverScrollViewContentOffset else {
                return
            }

            if let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? NSValue, let oldValue = change[NSKeyValueChangeKey.oldKey] as? NSValue {
                if newValue.cgPointValue != oldValue.cgPointValue {
                    let offset = scrollView.contentOffset.x / scrollView.bounds.width
                    let currentPageIndex = Int(offset + 0.5)
                    let previousIndex = _selectedIndex
                    if _selectedIndex != currentPageIndex {
                        _selectedIndex = currentPageIndex
                        segmentedControl.selectedSegmentIndex = currentPageIndex
                        loadSubControllerIfNeeded()
                        segmentedViewController[currentPageIndex].beginAppearanceTransition(true, animated: false)
                        segmentedViewController[currentPageIndex].endAppearanceTransition()
                        segmentedViewController[previousIndex].beginAppearanceTransition(false, animated: false)
                        segmentedViewController[previousIndex].endAppearanceTransition()
//                        adjustOffset(from: previousIndex, to: currentPageIndex)
                    }

                    if offset == trunc(offset) {
                        delegate?.didScrollToPageAtIndex?(currentPageIndex)
                    }
                }
            }
        } else {
            if pageTurning { return }

            guard selectedIndex >= 0, selectedIndex < segmentedViewController.count else { return }
            let selectedViewController = segmentedViewController[selectedIndex]
            if let scrollView = self.scrollViewWithSubViewController(viewController: selectedViewController) {
                if let objectScrollView = object as? UIScrollView, scrollView != objectScrollView {
                    return
                }
                self.layoutHeaderViewAndTabBar()
            }
        }
        

    }
}

extension SegmentedViewController {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        disableObserverScrollViewContentOffset = true
        scrollView.contentOffset = CGPoint(x: CGFloat(segmentedControl.selectedSegmentIndex) * size.width, y: 0)
        coordinator.animate(alongsideTransition: nil, completion: { _ in self.disableObserverScrollViewContentOffset = false })
    }
}


// MARK: - UIScrollViewDelegate

extension SegmentedViewController: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.layoutSubViewControllerToSelectedViewController()
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
