/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

private let ToolbarBaseAnimationDuration: CGFloat = 0.2

class BraveScrollController: NSObject {
    enum ScrollDirection {
        case Up
        case Down
        case None  // Brave added
    }

    weak var browser: Browser? {
        willSet {
            self.scrollView?.delegate = nil
            self.scrollView?.removeGestureRecognizer(panGesture)
        }

        didSet {
            self.scrollView?.addGestureRecognizer(panGesture)
            scrollView?.delegate = self
        }
    }

    static var hideShowToolbarEnabled = true

    weak var header: UIView?
    weak var footer: UIView?
    weak var urlBar: URLBarView?
    weak var snackBars: UIView?

    var keyboardIsShowing = false
    var verticalTranslation = CGFloat(0)

    var footerBottomConstraint: Constraint?
    var headerTopConstraint: Constraint?
    var toolbarsShowing: Bool { return headerTopOffset == 0 }

    private var headerTopOffset: CGFloat = 0 {
        didSet {
            headerTopConstraint?.updateOffset(headerTopOffset)
            header?.superview?.setNeedsLayout()
        }
    }

    private var footerBottomOffset: CGFloat = 0 {
        didSet {
            footerBottomConstraint?.updateOffset(footerBottomOffset)
            footer?.superview?.setNeedsLayout()
        }
    }

    private lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: "handlePan:")
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        return panGesture
    }()

    private var scrollView: UIScrollView? { return browser?.webView?.scrollView }
    private var contentOffset: CGPoint { return scrollView?.contentOffset ?? CGPointZero }
    private var contentSize: CGSize { return scrollView?.contentSize ?? CGSizeZero }
    private var scrollViewHeight: CGFloat { return scrollView?.frame.height ?? 0 }
    private var headerFrame: CGRect { return header?.frame ?? CGRectZero }
    private var footerFrame: CGRect { return footer?.frame ?? CGRectZero }
    private var snackBarsFrame: CGRect { return snackBars?.frame ?? CGRectZero }

    private var lastContentOffset: CGFloat = 0
    private var scrollDirection: ScrollDirection = .Down

    // Brave added
    // What I am seeing on older devices is when scroll direction is changed quickly, and the toolbar show/hides,
    // the first or second pan gesture after that will report the wrong direction (the gesture handling seems bugging during janky scrolling)
    // This added check is a secondary validator of the scroll direction
    private var scrollViewWillBeginDragPoint: CGFloat = 0

    override init() {
        super.init()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "pageUnload", name: kNotificationPageUnload, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillAppear:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillDisappear:", name: UIKeyboardWillHideNotification, object: nil)
    }

    func keyboardWillAppear(notification: NSNotification){
        keyboardIsShowing = true
    }

    func keyboardWillDisappear(notification: NSNotification){
        keyboardIsShowing = false
    }

    func pageUnload() {
        delay(0.1) {
            self.showToolbars(animated: true)
        }
    }

    func checkHeightOfPageAndAdjustWebViewInsents() {
        if !isScrollHeightIsLargeEnoughForScrolling() {
            if (scrollView?.contentInset.bottom == 0) {
                scrollView?.contentInset = UIEdgeInsetsMake(0, 0, UIConstants.ToolbarHeight * 2, 0)
            }
        } else {
            if (scrollView?.contentInset.bottom != 0) {
                scrollView?.contentInset = UIEdgeInsetsZero
            }
        }
    }

    func showToolbars(animated animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
        checkHeightOfPageAndAdjustWebViewInsents()

        if verticalTranslation == 0 && headerTopOffset == 0 {
            completion?(finished: true)
            return
        }

        let durationRatio = abs(headerTopOffset / headerFrame.height)
        let actualDuration = NSTimeInterval(ToolbarBaseAnimationDuration * durationRatio)
        self.animateToolbarsWithOffsets(
            animated: animated,
            duration: actualDuration,
            headerOffset: 0,
            footerOffset: 0,
            alpha: 1,
            completion: completion)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "contentSize" {
            checkHeightOfPageAndAdjustWebViewInsents()
            if !isScrollHeightIsLargeEnoughForScrolling() && !toolbarsShowing {
                showToolbars(animated: true, completion: nil)
            }
        }
    }
}

private extension BraveScrollController {
    func browserIsLoading() -> Bool {
        return browser?.loading ?? true
    }

    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        if browserIsLoading() /*|| BraveUX.IsToolbarHidingOff */ {
            return
        }

        if !BraveScrollController.hideShowToolbarEnabled {
            return
        }

        guard let containerView = scrollView?.superview else { return }

        let translation = gesture.translationInView(containerView)
        let delta = lastContentOffset - translation.y

        if delta > 0 && contentOffset.y - scrollViewWillBeginDragPoint >= 1.0 {
            scrollDirection = .Down
        } else if delta < 0 && scrollViewWillBeginDragPoint - contentOffset.y >= 1.0 {
            scrollDirection = .Up
        }

        lastContentOffset = translation.y
        if isScrollHeightIsLargeEnoughForScrolling() {
            scrollWithDelta(delta)
        }

        if gesture.state == .Ended || gesture.state == .Cancelled {
            lastContentOffset = 0
        }
    }

    func scrollWithDelta(delta: CGFloat) {
        if scrollViewHeight >= contentSize.height {
            return
        }

        if snackBars?.frame.size.height > 0 {
            return
        }

        if refreshControl?.hidden == false {
            return
        }

        let updatedOffset = toolbarsShowing ? clamp(verticalTranslation - delta, min: -UIConstants.ToolbarHeight, max: 0) :
            clamp(verticalTranslation - delta, min: 0, max: UIConstants.ToolbarHeight)

        verticalTranslation = updatedOffset

        header?.layer.sublayerTransform = CATransform3DMakeAffineTransform(CGAffineTransformMakeTranslation(0, verticalTranslation))
        footer?.layer.sublayerTransform = CATransform3DMakeAffineTransform(CGAffineTransformMakeTranslation(0, -verticalTranslation))

        let webViewVertTranslation = toolbarsShowing ? verticalTranslation : verticalTranslation - UIConstants.ToolbarHeight
        let webView = getApp().browserViewController.webViewContainer
        webView.layer.sublayerTransform = CATransform3DMakeAffineTransform(CGAffineTransformMakeTranslation(0, webViewVertTranslation))

        var alpha = 1 - abs(verticalTranslation / UIConstants.ToolbarHeight)
        if (!toolbarsShowing) {
            alpha = 1 - alpha
        }
        urlBar?.updateAlphaForSubviews(alpha)
    }

    func clamp(y: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        if y >= max {
            return max
        } else if y <= min {
            return min
        }
        return y
    }

    func animateToolbarsWithOffsets(animated animated: Bool, duration: NSTimeInterval, headerOffset: CGFloat,
        footerOffset: CGFloat, alpha: CGFloat, completion: ((finished: Bool) -> Void)?) {
            let isShow = headerOffset == 0

            let animation: () -> Void = {
                self.headerTopOffset = headerOffset
                self.footerBottomOffset = footerOffset
                self.urlBar?.updateAlphaForSubviews(alpha)
                self.header?.layoutIfNeeded()
                self.footer?.layoutIfNeeded()
            }

            // Reset the scroll direction now that it is handled
            scrollDirection = .None

            let requiredOffsetForHide = self.contentOffset.y - UIConstants.ToolbarHeight
            if !isShow{
                scrollView?.contentOffset.y = requiredOffsetForHide
            }

            let completionWrapper: Bool -> Void = { finished in
                completion?(finished: finished)
                if !isShow {
                    self.scrollView?.contentOffset.y = requiredOffsetForHide
                }
            }

            if animated {
                UIView.animateWithDuration(0.350, delay:0.0, options: .AllowUserInteraction, animations: animation, completion: completionWrapper)
            } else {
                animation()
                completion?(finished: true)
            }
    }

    func isScrollHeightIsLargeEnoughForScrolling() -> Bool {
        return (UIScreen.mainScreen().bounds.size.height + 2 * UIConstants.ToolbarHeight) < scrollView?.contentSize.height
    }
}

extension BraveScrollController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
    }
}

func blockOtherGestures(isBlocked: Bool, views: [UIView]) {
    for view in views {
        if let gestures = view.gestureRecognizers as [UIGestureRecognizer]! {
            for gesture in gestures {
                gesture.enabled = !isBlocked
            }
        }
    }
}

var refreshControl:ODRefreshControl?
// stop refresh interaction while animating
var isInRefreshQuietPeriod:Bool = false
// only allow refresh when scrolling with finger down, not from a momentum scrll
var isRefreshBlockedDueToMomentumScroll = false

extension BraveScrollController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard let webView = browser?.webView else { return }
        let position = -webView.convertPoint(webView.frame.origin, fromView: nil).y
        if contentOffset.y < 0 && !isInRefreshQuietPeriod && !isRefreshBlockedDueToMomentumScroll && verticalTranslation == 0 && toolbarsShowing {
            if refreshControl == nil {
                refreshControl = ODRefreshControl(inScrollView: getApp().rootViewController.view)
                refreshControl?.backgroundColor = UIColor.blackColor()
            }
            refreshControl?.hidden = false
            refreshControl?.frame = CGRectMake(0, position, refreshControl?.frame.size.width ?? 0, -contentOffset.y)

            if Int(contentOffset.y) < -BraveUX.PullToReloadDistance && !keyboardIsShowing {
                isInRefreshQuietPeriod = true

                let currentOffset =  scrollView.contentOffset.y
                blockOtherGestures(true, views: scrollView.subviews)
                blockOtherGestures(true, views: [scrollView])
                scrollView.contentOffset.y = currentOffset
                refreshControl?.beginRefreshing()
                browser?.webView?.reloadFromOrigin()
                UIView.animateWithDuration(0.5, animations: { refreshControl?.backgroundColor = UIColor.clearColor() })
                UIView.animateWithDuration(0.5, delay: 0.2, options: .AllowAnimatedContent, animations: {
                    scrollView.contentOffset.y = 0
                    refreshControl?.frame = CGRectMake(0, position, refreshControl?.frame.size.width ?? 0, 0)
                    }, completion: {
                        finished in
                        blockOtherGestures(false, views: scrollView.subviews)
                        blockOtherGestures(false, views: [scrollView])
                        isInRefreshQuietPeriod = false
                        refreshControl?.endRefreshing()
                        refreshControl?.hidden = true
                        refreshControl?.backgroundColor = UIColor.blackColor()
                })
            }
        } else if refreshControl?.hidden == false {
            refreshControl?.frame = CGRectMake(0, position, refreshControl?.frame.size.width ?? 0, -contentOffset.y)
        }

        if contentOffset.y >= 0 && refreshControl?.hidden == false && !isInRefreshQuietPeriod {
            refreshControl?.hidden = true
        }
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if browserIsLoading() {
            return
        }

        if (!decelerate) {
            removeTranslationAndSetLayout()
        } else {
            isRefreshBlockedDueToMomentumScroll = true
        }
    }

    func removeTranslationAndSetLayout() {
        if verticalTranslation == 0 {
            return
        }
        
        if verticalTranslation < 0 && headerTopOffset == 0 {
            headerTopOffset = -UIConstants.ToolbarHeight
            footerBottomOffset = UIConstants.ToolbarHeight
            urlBar?.updateAlphaForSubviews(0)
        } else if verticalTranslation > UIConstants.ToolbarHeight / 2.0 && headerTopOffset != 0 {
            headerTopOffset = 0
            footerBottomOffset = 0
            urlBar?.updateAlphaForSubviews(1.0)
        }
        
        verticalTranslation = 0
        header?.layer.sublayerTransform = CATransform3DIdentity
        footer?.layer.sublayerTransform = CATransform3DIdentity
        
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.scrollViewWillBeginDragPoint = scrollView.contentOffset.y
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.removeTranslationAndSetLayout()
        isRefreshBlockedDueToMomentumScroll = false
    }

    func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        showToolbars(animated: true)
        return true
    }
}
