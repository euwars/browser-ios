/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

private let ToolbarBaseAnimationDuration: CGFloat = 0.2

class BraveBrowserScrollController: NSObject {
  enum ScrollDirection {
    case Up
    case Down
  }

  enum ToolbarState {
    case Collapsed
    case Visible
    case Animating
  }

  weak var browser: Browser? {
    willSet {
      self.scrollView?.delegate = nil
      self.scrollView?.removeGestureRecognizer(panGesture)
    }

    didSet {
      guard let scrollView = self.scrollView else { return }
      scrollView.addGestureRecognizer(panGesture)
      scrollView.delegate = self
    }
  }

  weak var header: UIView?
  weak var footer: UIView?
  weak var urlBar: URLBarView?
  weak var snackBars: UIView?

  var footerBottomConstraint: Constraint?
  // TODO: Since SnapKit hasn't added support yet (Swift 2.0/iOS 9) for handling layoutGuides,
  // this constraint uses the system abstraction instead of SnapKit's Constraint class
  var headerTopConstraint: NSLayoutConstraint?
  var toolbarsShowing: Bool { return headerTopOffset == 0 }

  private var headerTopOffset: CGFloat = 0 {
    didSet {
      headerTopConstraint?.constant = headerTopOffset
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
  private var contentHeight: CGFloat {
    let height = browser?.webView?.sizeThatFits(CGSizeMake(1, 1)).height
    return height ?? 0.0
  }
  private var scrollViewHeight: CGFloat { return scrollView?.frame.height ?? 0 }
  private var headerFrame: CGRect { return header?.frame ?? CGRectZero }
  private var footerFrame: CGRect { return footer?.frame ?? CGRectZero }
  private var snackBarsFrame: CGRect { return snackBars?.frame ?? CGRectZero }

  private var lastContentOffset: CGFloat = 0
  private var scrollDirection: ScrollDirection = .Down
  private var toolbarState: ToolbarState = .Visible

  override init() {
    super.init()
  }

  func showToolbars(animated animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
    if (toolbarState == .Visible) {
      return
    }

    let durationRatio = abs(headerTopOffset / headerFrame.height)
    let actualDuration = NSTimeInterval(ToolbarBaseAnimationDuration * durationRatio)
    self.animateToolbarsWithOffsets(
      animated: animated,
      duration: actualDuration,
      headerOffset: 0,
      footerOffset: 0,
      changeInsets: true,
      alpha: 1,
      completion: completion)
  }

  func hideToolbars(animated animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
    if (toolbarState == .Collapsed) {
      return
    }

    toolbarState = .Collapsed
    let durationRatio = abs((headerFrame.height + headerTopOffset) / headerFrame.height)
    let actualDuration = NSTimeInterval(ToolbarBaseAnimationDuration * durationRatio)
    self.animateToolbarsWithOffsets(
      animated: animated,
      duration: actualDuration,
      headerOffset: -headerFrame.height,
      footerOffset: footerFrame.height - snackBarsFrame.height,
      changeInsets: true,
      alpha: 0,
      completion: completion)
  }

  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if keyPath == "contentSize" {
      if browserIsLoading() ||
        scrollViewHeight >= contentHeight {
        setupInsetsForTransparentBars(show: true)
      }
    }
  }


  func setupInsetsForTransparentBars(show show: Bool) {
    let insetHeight = show ? CGFloat(UIConstants.ToolbarHeight) : 0
    guard let scrollView = self.scrollView else { return }
    if (scrollView.contentInset.top != insetHeight) {
      let footerInset = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 0 : insetHeight
      scrollView.contentInset = UIEdgeInsetsMake(insetHeight, 0, footerInset, 0)
      scrollView.scrollIndicatorInsets = scrollView.contentInset
    }
  }
}

private extension BraveBrowserScrollController {
  func browserIsLoading() -> Bool {
    return browser?.loading ?? true
  }

  @objc func handlePan(gesture: UIPanGestureRecognizer) {
    if browserIsLoading() {
      showToolbars(animated: true)
      return
    }

    guard let containerView = scrollView?.superview else { return }
    let translation = gesture.translationInView(containerView)
    let delta = lastContentOffset - translation.y

    if delta > 0 {
      scrollDirection = .Down
    } else if delta < 0 {
      scrollDirection = .Up
    }

    lastContentOffset = translation.y
    if !isRubberbandingWhileFingerDraggingUp(delta: delta) {
      //checkScrollHeightIsLargeEnoughForScrolling() {
      //if toolbarState != .Collapsed || contentOffset.y <= 0 {
        scrollWithDelta(delta)
      //}

      if headerTopOffset == -headerFrame.height {
        toolbarState = .Collapsed
      } else if headerTopOffset == 0 {
        toolbarState = .Visible
      } else {
        toolbarState = .Animating
      }
      //print("\(toolbarState)")
    }

    if gesture.state == .Ended || gesture.state == .Cancelled {
      lastContentOffset = 0
    }
  }

  // If moving upward while bouncing we return false, there must be finger actively dragging to return true
  func isRubberbandingWhileFingerDraggingUp(delta delta: CGFloat) -> Bool {
    if contentOffset.y < -UIConstants.ToolbarHeight {
      return true
    }

    let scrollingIsUp = delta < 0
    let scrolledPastTheBottom = contentOffset.y + scrollViewHeight > contentHeight
    let contentBiggerThanView = scrollViewHeight < contentHeight

    let isScrolledPastBottomAndBeingDraggedUp = scrollingIsUp && scrolledPastTheBottom && contentBiggerThanView
    return isScrolledPastBottomAndBeingDraggedUp
  }

  // MARK: This moves the toolbar in sync with user pan gesture
  func scrollWithDelta(delta: CGFloat) {
    if scrollViewHeight >= contentHeight {
      return
    }
    if delta <= 0 && toolbarState == .Visible {
      return
    }
    if delta >= 0 && toolbarState == .Collapsed {
     return
    }

    var updatedOffset = headerTopOffset - delta
    headerTopOffset = clamp(updatedOffset, min: -headerFrame.height, max: 0)
    updatedOffset = footerBottomOffset + delta
    footerBottomOffset = clamp(updatedOffset, min: 0, max: footerFrame.height - snackBarsFrame.height)
    let alpha = 1 - abs(headerTopOffset / headerFrame.height)
    urlBar?.updateAlphaForSubviews(alpha)

    guard let scrollView = self.scrollView else { return }
    scrollView.contentInset = UIEdgeInsetsMake(UIConstants.ToolbarHeight + self.headerTopOffset, 0,
      UIConstants.ToolbarHeight - footerBottomOffset, 0)
    scrollView.scrollIndicatorInsets = scrollView.contentInset
  }

  func isHeaderDisplayedForGivenOffset(offset: CGFloat) -> Bool {
    return offset > -headerFrame.height && offset < 0
  }

  func clamp(y: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
    if y >= max {
      return max
    } else if y <= min {
      return min
    }
    return y
  }

  func animateToolbarsWithOffsets(
    animated animated: Bool,
    duration: NSTimeInterval,
    headerOffset: CGFloat,
    footerOffset: CGFloat,
    changeInsets: Bool,
    alpha: CGFloat,
    completion: ((finished: Bool) -> Void)?) {

      struct Guard {
        static var isAnimatorRunning = false
      }

      if Guard.isAnimatorRunning {
        return
      }

      toolbarState = .Animating

      let completionWrapper:((finished: Bool) -> Void)? = { finished in
        self.toolbarState == .Visible
        Guard.isAnimatorRunning = false
        completion?(finished: finished)
      }

      let animation: () -> Void = {
        self.headerTopOffset = headerOffset
        self.footerBottomOffset = footerOffset
        self.urlBar?.updateAlphaForSubviews(alpha)
        self.header?.superview?.layoutIfNeeded()
        if changeInsets {
          self.setupInsetsForTransparentBars(show: headerOffset == 0)
        }
      }

      if animated {
        Guard.isAnimatorRunning = true
        UIView.animateWithDuration(duration, delay:0, options: UIViewAnimationOptions(rawValue: 0), animations: animation, completion: completionWrapper)
      } else {
        animation()
        completion?(finished: true)
      }
  }

  func checkScrollHeightIsLargeEnoughForScrolling() -> Bool {
    return true
//    let h = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? UIConstants.ToolbarHeight : UIConstants.ToolbarHeight * 2
//    let result = (UIScreen.mainScreen().bounds.size.height + CGFloat(h)) < contentHeight
//    //print("checkScrollHeightIsLargeEnoughForScrolling \(result)")
//    return result
  }
}

extension BraveBrowserScrollController: UIGestureRecognizerDelegate {
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
      return true
  }
}

extension BraveBrowserScrollController: UIScrollViewDelegate {
  func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if browserIsLoading() {
      return
    }

    if (decelerate || (toolbarState == .Animating && !decelerate)) && checkScrollHeightIsLargeEnoughForScrolling() {
      if scrollDirection == .Up {
        self.showToolbars(animated: true)
      } else if scrollDirection == .Down {
        self.hideToolbars(animated: true)
      }
    }
  }
}
