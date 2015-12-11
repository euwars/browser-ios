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
            self.scrollView?.addGestureRecognizer(panGesture)
            scrollView?.delegate = self
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
    private var contentSize: CGSize { return scrollView?.contentSize ?? CGSizeZero }
    private var scrollViewHeight: CGFloat { return scrollView?.frame.height ?? 0 }
    private var headerFrame: CGRect { return header?.frame ?? CGRectZero }
    private var footerFrame: CGRect { return footer?.frame ?? CGRectZero }
    private var snackBarsFrame: CGRect { return snackBars?.frame ?? CGRectZero }

    private var lastContentOffset: CGFloat = 0
    private var scrollDirection: ScrollDirection = .Down
    private var toolbarState: ToolbarState = .Visible

    // Brave added
    // What I am seeing on older devices is when scroll direction is changed quickly, and the toolbar show/hides,
    // the first or second pan gesture after that will report the wrong direction (the gesture handling seems bugging during janky scrolling)
    // This added check is a secondary validator of the scroll direction, however one can no longer scroll up and down in a single gesture
    // to show and hide toolbars, they must be separate gestures.
    // This all avoids a worst case where the toolbar hides/shows, triggers some jank, user swipes during jank, and the toolbar wrongly shows (and triggers more jank)
    private var scrollViewWillBeginDragPoint: CGFloat = 0

    override init() {
        super.init()
    }

  func showToolbars(animated animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
    showToolbars(adjustContentOffset: false, animated: animated, completion: completion)
  }

    func showToolbars(adjustContentOffset adjustContentOffset: Bool, animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
        if toolbarState == .Visible || toolbarsShowing {
        return
      }
      toolbarState = .Visible
      let durationRatio = abs(headerTopOffset / headerFrame.height)
      let actualDuration = NSTimeInterval(ToolbarBaseAnimationDuration * durationRatio)
      self.animateToolbarsWithOffsets(
        adjustContentOffset: adjustContentOffset,
        animated: animated,
        duration: actualDuration,
        headerOffset: 0,
        footerOffset: 0,
        alpha: 1,
        completion: completion)
    }

    func hideToolbars(animated animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
      hideToolbars(adjustContentOffset:false, animated: animated, completion: completion)
    }

    func hideToolbars(adjustContentOffset adjustContentOffset: Bool, animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
      if toolbarState == .Collapsed || !toolbarsShowing {
        return
      }

      if !checkScrollHeightIsLargeEnoughForScrolling() {
        return
      }

      toolbarState = .Collapsed
        let durationRatio = abs((headerFrame.height + headerTopOffset) / headerFrame.height)
        let actualDuration = NSTimeInterval(ToolbarBaseAnimationDuration * durationRatio)
        self.animateToolbarsWithOffsets(
            adjustContentOffset: adjustContentOffset,
            animated: animated,
            duration: actualDuration,
            headerOffset: -headerFrame.height,
            footerOffset: footerFrame.height - snackBarsFrame.height,
            alpha: 0,
            completion: completion)
    }

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
        if browserIsLoading() {
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
        if checkRubberbandingForDelta(delta) && checkScrollHeightIsLargeEnoughForScrolling() {
            if toolbarState != .Collapsed || contentOffset.y <= 0 {
                scrollWithDelta(delta)
            }

            if headerTopOffset == -headerFrame.height {
                toolbarState = .Collapsed
            } else if headerTopOffset == 0 {
                toolbarState = .Visible
            } else {
                toolbarState = .Animating
            }
        }

        if gesture.state == .Ended || gesture.state == .Cancelled {
            lastContentOffset = 0
        }
    }

    func checkRubberbandingForDelta(delta: CGFloat) -> Bool {
        return !((delta < 0 && contentOffset.y + scrollViewHeight > contentSize.height &&
                scrollViewHeight < contentSize.height) ||
                contentOffset.y < delta)
    }

    func scrollWithDelta(delta: CGFloat) {
      if (!BraveUX.IsHighLoadAnimationAllowed) {
        return
      }

        if scrollViewHeight >= contentSize.height {
            return
        }

        var updatedOffset = headerTopOffset - delta
        headerTopOffset = clamp(updatedOffset, min: -headerFrame.height, max: 0)
        if isHeaderDisplayedForGivenOffset(updatedOffset) {
            scrollView?.contentOffset = CGPoint(x: contentOffset.x, y: contentOffset.y - delta)
        }

        updatedOffset = footerBottomOffset + delta
        footerBottomOffset = clamp(updatedOffset, min: 0, max: footerFrame.height - snackBarsFrame.height)

        let alpha = 1 - abs(headerTopOffset / headerFrame.height)
        urlBar?.updateAlphaForSubviews(alpha)
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

  func animateToolbarsWithOffsets(adjustContentOffset adjustContentOffset: Bool,
     animated: Bool, var duration: NSTimeInterval, headerOffset: CGFloat,
        footerOffset: CGFloat, alpha: CGFloat, completion: ((finished: Bool) -> Void)?) {
        let animation: () -> Void = {
            if (adjustContentOffset) {
              self.scrollView?.contentOffset.y += headerOffset != 0 ? headerOffset : UIConstants.ToolbarHeight
            }
            self.headerTopOffset = headerOffset
            self.footerBottomOffset = footerOffset
            self.urlBar?.updateAlphaForSubviews(alpha)
            self.header?.superview?.layoutIfNeeded()
        }

        // Reset the scroll direction now that it is handled
        scrollDirection = .None

          if !BraveUX.IsHighLoadAnimationAllowed {
            duration /= 2.0
          }

        if animated {
          UIView.animateWithDuration(duration, delay:0.0, options: .AllowUserInteraction, animations: animation, completion: completion)
        } else {
            animation()
            completion?(finished: true)
        }
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

      if (BraveUX.IsHighLoadAnimationAllowed) {
        if (decelerate || (toolbarState == .Animating && !decelerate)) && checkScrollHeightIsLargeEnoughForScrolling() {
            if scrollDirection == .Up {
               showToolbars(animated: true)
            } else if scrollDirection == .Down {
                hideToolbars(animated: true)
            }
        }
      } else {
        if (!decelerate) {
          if scrollDirection == .Down && scrollView.contentOffset.y > UIConstants.ToolbarHeight {
            hideToolbars(adjustContentOffset: true, animated: true)
          }

          if (scrollDirection == .Up) {
            showToolbars(adjustContentOffset: true, animated: true)
          }
        }
      }
    }

  func scrollViewWillBeginDragging(scrollView: UIScrollView) {
    self.scrollViewWillBeginDragPoint = scrollView.contentOffset.y
  }

  func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    if (!BraveUX.IsHighLoadAnimationAllowed) {
      if scrollDirection == .Down {
        hideToolbars(adjustContentOffset: true, animated: true)
      }

      if scrollDirection == .Up {
        showToolbars(adjustContentOffset: true, animated: true)
      }
    }
  }

    func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        showToolbars(animated: true)
        return true
    }
}
