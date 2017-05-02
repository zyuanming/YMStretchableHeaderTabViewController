
import UIKit

protocol StretchableHeaderViewDelegate: class {
    func interactiveSubviews(in headerView: StretchableHeaderView) -> [UIView]
}

class StretchableHeaderView: UIView {
    weak var delegate: StretchableHeaderViewDelegate?
    var minimumOfHeight: CGFloat = 0
    var maximumOfHeight: CGFloat = 128
    var bounces: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureHeaderView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let targetView = super.hitTest(point, with: event) else { return nil}

        var interactiveSubviews: [UIView] = []
        if let delegate = delegate {
            interactiveSubviews = delegate.interactiveSubviews(in: self)
        } else {
            return targetView
        }

        if interactiveSubviews.contains(self) {
            return targetView
        }

        // Recursive search interactive view in children
        var isFound = false
        var checkView = targetView
        while checkView != self {
            for subView in interactiveSubviews {
                if checkView == subView {
                    isFound = true
                    break
                }
            }

            if isFound {
                return targetView
            }
            if let parentView = checkView.superview {
                checkView = parentView
            }
        }

        return nil
    }

    private func configureHeaderView() {
        clipsToBounds = true
    }
}
