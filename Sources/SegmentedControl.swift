
import UIKit

open class SegmentedControl: UIControl {

    struct SegmentedItem: ExpressibleByStringLiteral {

        fileprivate enum ItemType {
            case image(normal: UIImage?, selected: UIImage?)
            case title(String)
        }

        fileprivate var type: ItemType

        init(value: String) {
            type = .title(value)
        }

        init(stringLiteral value: String) {
            type = .title(value)
        }

        init(unicodeScalarLiteral value: String) {
            type = .title(value)
        }

        init(extendedGraphemeClusterLiteral value: String) {
            type = .title(value)
        }
        
        init(normal: UIImage?, selected: UIImage?) {
            type = .image(normal: normal, selected: selected)
        }
    }

    var selectionIndicatorHeight: CGFloat = 2.5
    var animationDuration: TimeInterval = 0.2
    var segmentNormalColor: UIColor = UIColor.black.withAlphaComponent(0.6)
    var segmentDisabledColor: UIColor = UIColor.black.withAlphaComponent(0.6)
    var isItemScrollEnabled = true

    var kJumpFlag: Bool = false

    var items: [SegmentedItem] = [] {
        willSet { removeAllSegments() }
        didSet { insertAllSegments() }
    }
    
    var normalFont   = UIFont.systemFont(ofSize: 16)
    var selectedFont = UIFont.systemFont(ofSize: 17)
    
    var numberOfSegments: Int {
        return items.count
    }
    
    var selectedSegmentIndex: Int {
        get { return _selectedSegmentIndex }
        set {
            setSelected(true, forSegmentAtIndex: newValue)
        }
    }
    
    var isTopSeparatorHidden: Bool {
        get { return separatorTopLine.isHidden }
        set { separatorTopLine.isHidden = newValue }
    }
    
    fileprivate var _selectedSegmentIndex = 0
    fileprivate var segmentsButtons: [UIButton] = []
    fileprivate(set) var segmentsContainerView: UIScrollView?
    fileprivate var indicatorView = UIView()
    fileprivate var separatorTopLine = UIView()
    fileprivate var separatorLine = UIView()


    //MARK: lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    convenience init(items: [SegmentedItem]) {
        self.init()
        self.items = items
        
        insertAllSegments()

    }
    
    fileprivate func commonInit() {
        separatorTopLine.isHidden = true
        separatorTopLine.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        separatorLine.backgroundColor = UIColor.black.withAlphaComponent(0.1)
    }
    
    //MARK:
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        if segmentsButtons.count == 0 {
            selectedSegmentIndex = -1;
        } else if selectedSegmentIndex < 0 {
            selectedSegmentIndex = 0
        }
        
        configureSegments()
        layoutButtons()
        layoutIndicator()
        layoutSeparator()
    }
    
    override open func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        setColors()
    }
    
    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        setColors()
    }
    
    open func setSelected(_ selected: Bool, forSegmentAtIndex index: Int) {
        guard 0 <= index, index < segmentsButtons.count else { return }

        layoutSelectedOffset(at: index)

        if selectedSegmentIndex == index {
            return
        }
        
        let previousButton = buttonAtIndex(selectedSegmentIndex)
        let currentButton = buttonAtIndex(index)
        let isPreviousButtonShowAnimation = isButtonTitlePresentation(at: selectedSegmentIndex)
        let isCurrentButtonShowAnimation = isButtonTitlePresentation(at: index)

        previousButton?.isUserInteractionEnabled = true
        previousButton?.isSelected = false
        
        currentButton?.isSelected = true
        currentButton?.isUserInteractionEnabled = false

        _selectedSegmentIndex = index

        var scale: CGFloat = 1
        if let selectHeight = previousButton?.titleLabel?.bounds.height, let normalHeight = currentButton?.titleLabel?.bounds.height, let t = previousButton?.transform {
            if normalHeight > 0 && selectHeight > 0 && t.a + t.c > 0 {
                //缩放大小 ＝ 选中的字体高度 * 仿射变换的缩放系数 / 未选中的字体高度
                scale = selectHeight * sqrt(t.a * t.a + t.c * t.c) / normalHeight
            }
        }

        UIView.animate(withDuration: animationDuration,
            delay: 0,
            options: .beginFromCurrentState,
            animations: {
                self.layoutIndicator()
                if isPreviousButtonShowAnimation {
                    previousButton?.transform = CGAffineTransform(scaleX: 1 / scale, y: 1 / scale)
                }
                if isCurrentButtonShowAnimation {
                    currentButton?.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
            },
            completion: { _ in

                previousButton?.transform = CGAffineTransform.identity
                currentButton?.transform = CGAffineTransform.identity
                previousButton?.titleLabel?.font = (previousButton?.isSelected ?? true) ? self.selectedFont : self.normalFont
                currentButton?.titleLabel?.font = (currentButton?.isSelected ?? true) ? self.selectedFont : self.normalFont

        })

    }
    
    //MARK: Private Methods
    
    fileprivate func setColors() {
        indicatorView.backgroundColor = tintColor
    }
    
    fileprivate func layoutIndicator() {
        if let button = selectedButton() {
            let rect = CGRect(x: button.frame.minX, y: bounds.height - selectionIndicatorHeight, width: button.frame.width, height: selectionIndicatorHeight)
            indicatorView.frame = rect
        }
    }
    
    fileprivate func layoutSeparator() {
        separatorTopLine.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 0.5)
        separatorLine.frame = CGRect(x: 0, y: bounds.height - 0.5, width: bounds.width, height: 0.5)
    }
    
    fileprivate func layoutButtons() {
        segmentsContainerView?.frame = bounds
        var originX: CGFloat = 4
        var margin: CGFloat = 11
        let buttonMargin: CGFloat = 10
        var allWidth: CGFloat = 0
        for index in 0..<segmentsButtons.count {
            if let button = buttonAtIndex(index) {
                button.sizeToFit()
                let rect = CGRect(x: margin + originX, y: 0, width: button.frame.width + buttonMargin, height: bounds.height - selectionIndicatorHeight)

                button.frame = rect
                button.isSelected = (index == selectedSegmentIndex)

                originX = originX + margin + rect.width + margin

                if index == segmentsButtons.count - 1 {
                    allWidth = button.frame.maxX + margin
                }
            }
        }

        if allWidth <= frame.width {
            segmentsContainerView?.contentSize = CGSize(width: frame.width, height: floor(bounds.height))
            let buttonContentAllWidth = allWidth - margin * CGFloat(segmentsButtons.count * 2)
            margin = (frame.width - (buttonContentAllWidth)) / CGFloat(segmentsButtons.count * 2)
            originX = 0
            for index in 0..<segmentsButtons.count {
                if let button = buttonAtIndex(index) {
                    let rect = CGRect(x: margin + originX, y: 0, width: button.frame.width, height: button.frame.height)

                    button.frame = rect
                    button.isSelected = (index == selectedSegmentIndex)

                    originX = originX + margin + rect.width + margin

                }
            }
        } else {
            segmentsContainerView?.contentSize = CGSize(width: allWidth + 50, height: floor(bounds.height))
        }
    }

    fileprivate func layoutSelectedOffset(at index: Int) {
        guard let segmentsContainerView = segmentsContainerView,
            let button = buttonAtIndex(index),
            isItemScrollEnabled else { return }

        var targetX = max(0, button.frame.midX - self.frame.width / 2.0)
        targetX = min(segmentsContainerView.contentSize.width - self.frame.width, targetX)
        targetX = max(0, targetX)
        let point = CGPoint(x: targetX, y: 0)
        segmentsContainerView.setContentOffset(point, animated: true)
    }

    
    fileprivate func insertAllSegments() {
        for index in 0..<items.count {
            addButtonForSegment(index)
        }
        setNeedsLayout()
    }
    
    fileprivate func removeAllSegments() {
        segmentsButtons.forEach { $0.removeFromSuperview() }
        segmentsButtons.removeAll(keepingCapacity: true)
    }
    
    fileprivate func addButtonForSegment(_ segment: Int) {

        let button = UIButton(type:.custom)
        
        button.addTarget(self, action: #selector(willSelected(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(didSelected(_:)), for: .touchUpInside)
        
        button.backgroundColor = nil
        button.isOpaque = true
        button.clipsToBounds = true
        button.adjustsImageWhenDisabled = false
        button.adjustsImageWhenHighlighted = false
        button.isExclusiveTouch = true
        button.tag = segment
        
        if segmentsContainerView == nil {
            segmentsContainerView = UIScrollView(frame: bounds)
            segmentsContainerView?.showsVerticalScrollIndicator = false
            segmentsContainerView?.showsHorizontalScrollIndicator = false
            segmentsContainerView?.backgroundColor = UIColor.clear
            segmentsContainerView?.isScrollEnabled = isItemScrollEnabled
            addSubview(segmentsContainerView!)

            self.sendSubview(toBack: segmentsContainerView!)

            addSubview(separatorTopLine)
            addSubview(separatorLine)
            segmentsContainerView?.addSubview(indicatorView)
        }
        
        segmentsButtons.append(button)
        segmentsContainerView?.addSubview(button)
    }
    
    fileprivate func buttonAtIndex(_ index: Int) -> UIButton? {
        if 0 <= index && index < segmentsButtons.count {
            return segmentsButtons[index]
        }
        return nil
    }
    
    fileprivate func selectedButton() -> UIButton? {
        return buttonAtIndex(selectedSegmentIndex)
    }
    
    fileprivate func titleForSegmentAtIndex(_ index: Int) -> String? {
        guard 0 <= index && index < items.count else { return nil }

        if case .title(let title) = items[index].type {
            return title
        }

        return nil
    }

    fileprivate func isButtonTitlePresentation(at position: Int) -> Bool {
        guard 0 <= position && position < items.count else { return false }
        if case .title = items[position].type {
            return true
        }
        return false
    }

    fileprivate func setButtonImages(at position: Int) {
        guard 0 <= position && position < items.count else { return }

        if case .image(let image) = items[position].type {
            let button = buttonAtIndex(position)
            button?.setImage(image.normal, for: UIControlState())
            button?.setImage(image.selected, for: .highlighted)
            button?.setImage(image.selected, for: .selected)
        }
    }
    
    fileprivate func configureSegments() {
        for button in segmentsButtons {
            configureButtonForSegment(button.tag)
        }
    }
    
    fileprivate func configureButtonForSegment(_ segment: Int) {

        assert(segment >= 0, "segment index must greater than 0")
        assert(segment < numberOfSegments, "segment button must exist")
        
        setFont(segment == selectedSegmentIndex ? selectedFont : normalFont, forSegmentAtIndex: segment)

        if let title = titleForSegmentAtIndex(segment) {
            setTitle(title, forSegmentAtIndex: segment)

            setTitleColor(titleColorForButtonState(UIControlState()), forState: UIControlState())
            setTitleColor(titleColorForButtonState(.highlighted), forState: .highlighted)
            setTitleColor(titleColorForButtonState(.selected), forState: .selected)
        } else {
            setButtonImages(at: segment)
        }
    }
    
    fileprivate func setFont(_ font: UIFont, forSegmentAtIndex index: Int) {
        let button = buttonAtIndex(index)
        button?.titleLabel?.font = font
    }
    
    fileprivate func setTitle(_ title: String, forSegmentAtIndex index: Int) {
        let button = buttonAtIndex(index)
        
        button?.setTitle(title, for: UIControlState())
        button?.setTitle(title, for: .highlighted)
        button?.setTitle(title, for: .selected)
        button?.setTitle(title, for: .disabled)
    }
    
    fileprivate func setTitleColor(_ color: UIColor, forState state: UIControlState) {
        for button in segmentsButtons {
            button.setTitleColor(color, for: state)
        }
    }
    
    fileprivate func titleColorForButtonState(_ state: UIControlState) -> UIColor {
        switch state {
        case UIControlState():		return segmentNormalColor
        case UIControlState.disabled:	return segmentDisabledColor
        default:						return tintColor
        }
    }
    
    //MARK: Segment Actions
    @objc fileprivate func willSelected(_ sender: UIButton) {
        
    }
    
    @objc fileprivate func didSelected(_ sender: UIButton) {
        if selectedSegmentIndex != sender.tag {
            selectedSegmentIndex = sender.tag
            sendActions(for: .valueChanged)
        }
    }
}

