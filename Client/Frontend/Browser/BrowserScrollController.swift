/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

private let ToolbarBaseAnimationDuration: CGFloat = 0.2

class BrowserScrollingController: NSObject {
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

    weak var header: UIView?
    weak var footer: UIView?
    weak var urlBar: URLBarView?
    weak var snackBars: UIView?

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
    }

    func pageUnload() {
      delay(0.1) {
        self.showToolbars(animated: true)
      }
    }

    func showToolbars(animated animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
      if verticalTranslation == 0 && headerTopOffset == 0 && !self.isLayoutPinnedToWindowExtents() {
        completion?(finished: true)
        return
      }

      layoutWebViewPinnedToHeaderFooter(triggerRedrawWithLayoutIfNeeded: false)

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

//    func hideToolbars(animated animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
//        let durationRatio = abs((headerFrame.height + headerTopOffset) / headerFrame.height)
//        let actualDuration = NSTimeInterval(ToolbarBaseAnimationDuration * durationRatio)
//        self.animateToolbarsWithOffsets(
//            animated: animated,
//            duration: actualDuration,
//            headerOffset: -headerFrame.height,
//            footerOffset: footerFrame.height - snackBarsFrame.height,
//            alpha: 0,
//            completion: completion)
//    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "contentSize" {
            if !checkScrollHeightIsLargeEnoughForScrolling() && !toolbarsShowing {
                showToolbars(animated: true, completion: nil)
            }
        }
    }
}

private extension BrowserScrollingController {
    func browserIsLoading() -> Bool {
        return browser?.loading ?? true
    }

    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        if browserIsLoading() /*|| BraveUX.IsToolbarHidingOff */ {
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
        if checkScrollHeightIsLargeEnoughForScrolling() {
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

      if headerTopOffset != 0 && headerTopOffset != -UIConstants.ToolbarHeight {
        assert(verticalTranslation == 0)
        return
      }

      let updatedOffset = toolbarsShowing ? clamp(verticalTranslation - delta, min: -UIConstants.ToolbarHeight, max: 0) :
        clamp(verticalTranslation - delta, min: 0, max: UIConstants.ToolbarHeight)
      verticalTranslation = updatedOffset


      header?.layer.sublayerTransform = CATransform3DMakeAffineTransform(CGAffineTransformMakeTranslation(0, verticalTranslation))
      footer?.layer.sublayerTransform = CATransform3DMakeAffineTransform(CGAffineTransformMakeTranslation(0, -verticalTranslation));

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
          self.layoutWebViewPinnedToWindowExtents()
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

    // TODO track the constraint
    func isLayoutPinnedToWindowExtents() -> Bool {
      guard let app = UIApplication.sharedApplication().delegate as? AppDelegate else { return false }
      let view = app.browserViewController.webViewContainer
      let constraints = view.constraintsAffectingLayoutForAxis(.Vertical)
      for (_, value) in constraints.enumerate() {
        if value.firstItem as? UIView == view {
          if value.secondItem as? UIView == app.browserViewController.statusBarOverlay {
            return true // is already set
          }
        }
      }
      return false
    }

    func layoutWebViewPinnedToHeaderFooter(triggerRedrawWithLayoutIfNeeded triggerRedrawWithLayoutIfNeeded: Bool) {
      if !isLayoutPinnedToWindowExtents() {
        return
      }

      guard let app = UIApplication.sharedApplication().delegate as? AppDelegate else { return }
      app.browserViewController.webViewContainer.snp_remakeConstraints {
        make in
        make.left.right.equalTo(app.browserViewController.view)
        make.top.equalTo(app.browserViewController.header.snp_bottom)
        make.bottom.equalTo(app.browserViewController.footer.snp_top)
      }

      if triggerRedrawWithLayoutIfNeeded {
        app.browserViewController.webViewContainer.layoutIfNeeded()
      }
      self.scrollView?.contentOffset.y += UIConstants.ToolbarHeight
  }

    func layoutWebViewPinnedToWindowExtents() {
      if isLayoutPinnedToWindowExtents() {
        return
      }

      guard let app = UIApplication.sharedApplication().delegate as? AppDelegate else { return }
      app.browserViewController.webViewContainer.snp_remakeConstraints {
        make in
        make.left.right.bottom.equalTo(app.browserViewController.view)
        make.top.equalTo(app.browserViewController.statusBarOverlay.snp_bottom)
      }

      self.scrollView?.contentOffset.y -= UIConstants.ToolbarHeight
    }

    func checkScrollHeightIsLargeEnoughForScrolling() -> Bool {
        return (UIScreen.mainScreen().bounds.size.height + 2 * UIConstants.ToolbarHeight) < scrollView?.contentSize.height
    }
}

extension BrowserScrollingController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension BrowserScrollingController: UIScrollViewDelegate {

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if browserIsLoading() {
            return
        }

        if (!decelerate) {
          removeTranslationAndSetLayout()
      }
    }

  func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    if contentOffset.y < 0 && verticalTranslation > UIConstants.ToolbarHeight / 2.0 && headerTopOffset != 0  {
      // user has scrolled past top (rubberbanding area) and toolbar needs to show. We show toolbar, and pin offset to zero so that when the 
      // toolbar shows, the page offset at top (i.e. y == 0) is shown
      removeTranslationAndSetLayout()
      scrollView.contentOffset.y = 0
    }
  }

    func removeTranslationAndSetLayout() {
      if verticalTranslation == 0 {
        return
      }

      if verticalTranslation < 0 && headerTopOffset == 0 {
        headerTopOffset = -UIConstants.ToolbarHeight
        footerBottomOffset = UIConstants.ToolbarHeight
        layoutWebViewPinnedToWindowExtents()
        urlBar?.updateAlphaForSubviews(0)
      } else if verticalTranslation > UIConstants.ToolbarHeight / 2.0 && headerTopOffset != 0 {
        headerTopOffset = 0
        footerBottomOffset = 0
        layoutWebViewPinnedToHeaderFooter(triggerRedrawWithLayoutIfNeeded: true)
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
        removeTranslationAndSetLayout()
    }

    func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        showToolbars(animated: true)
        return true
    }
}
