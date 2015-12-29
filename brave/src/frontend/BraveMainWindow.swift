// from: http://www.icab.de/blog/2010/07/11/customize-the-contextual-menu-of-uiwebview/

let kNotificationMainWindowTapAndHold = "kNotificationMainWindowTapAndHold"

class BraveMainWindow : UIWindow {
  var tapLocation:CGPoint = CGPointZero
  var contextualMenuTimer:NSTimer = NSTimer()

  lazy var contextMenuJs:String = {
    let path = NSBundle.mainBundle().pathForResource("BraveContextMenu", ofType: "js")!
    let source = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
    return source
  }()

  override func sendEvent(event: UIEvent) {
    super.sendEvent(event)

    if ((getApp().rootViewController.visibleViewController as? BraveTopViewController) == nil) {
      return
    }

 //   print("\(event.touchesForWindow(self))")
    if let touches = event.touchesForWindow(self), let touch = touches.first where touches.count == 1 {
      switch touch.phase {
      case .Began:  // A finger touched the screen
        tapLocation = touch.locationInView(self)
        contextualMenuTimer.invalidate()
        contextualMenuTimer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "tapAndHoldAction", userInfo: nil, repeats: false)
        break
      case .Ended, .Moved, .Stationary, .Cancelled:
        contextualMenuTimer.invalidate()
        break
      }
    } else {
      contextualMenuTimer.invalidate()
    }
  }

  func windowSizeAndScrollOffset(webView: LegacyWebView) ->(CGSize, CGPoint)? {
    let response = webView.stringByEvaluatingJavaScriptFromString("JSON.stringify({ width: window.innerWidth, height: window.innerHeight, x: window.pageXOffset, y: window.pageYOffset })")
    do {
      guard let json = try NSJSONSerialization.JSONObjectWithData((response?.dataUsingEncoding(NSUTF8StringEncoding))!, options: [])
        as? [String:AnyObject] else { return nil }
      if let w = json["width"] as? CGFloat,
        let h = json["height"] as? CGFloat,
        let x = json["x"] as? CGFloat,
        let y = json["y"] as? CGFloat {
          return (CGSizeMake(w, h), CGPointMake(x, y))
      }
      return nil
    } catch {
      return nil
    }
  }

  func tapAndHoldAction() {
    contextualMenuTimer.invalidate()
    let info = ["point": NSValue(CGPoint: tapLocation)]
    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationMainWindowTapAndHold, object: self, userInfo: info)

    guard let webView = getApp().browserViewController.tabManager.selectedTab?.webView else { return }
    var pt = webView.convertPoint(tapLocation, fromView: nil)

    let viewSize = webView.frame.size
    guard let (windowSize, _) = windowSizeAndScrollOffset(webView) else { return }

    let f = windowSize.width / viewSize.width;
    pt.x = pt.x * f;// + offset.x;
    pt.y = pt.y * f;// + offset.y;

    let result = webView.stringByEvaluatingJavaScriptFromString(contextMenuJs + "(\(pt.x), \(pt.y))")
    print("\(result)")

    guard let response = result where response.characters.count > "{}".characters.count else { return }

    func responseToElement(response: String) -> ContextMenuHelper.Elements? {
      do {
        guard let json = try NSJSONSerialization.JSONObjectWithData((response.dataUsingEncoding(NSUTF8StringEncoding))!, options: [])
          as? [String:AnyObject] else { return nil }
        if let image = json["imagesrc"] as? String,
          let url = json["link"] as? String {
            return ContextMenuHelper.Elements(link: NSURL(string: url), image: NSURL(string: image))
        }
      } catch {
      }
      return nil
    }

    func blockOtherGestures(views: [UIView]?) {
      guard let views = views else { return }
      for view in views {
        if let gestures = view.gestureRecognizers as [UIGestureRecognizer]! {
          for gesture in gestures {
            if gesture is UILongPressGestureRecognizer {
              // toggling gets the gesture to ignore this long press
              gesture.enabled = false
              gesture.enabled = true
            }
          }
        }
      }
    }

    blockOtherGestures(webView.scrollView.subviews)

    if let elements = responseToElement(response) {
      guard let bvc = getApp().browserViewController else { return }
      bvc.showContextMenu(elements: elements, touchPoint: tapLocation)
    }
  }
}