// Using suggestions from: http://www.icab.de/blog/2010/07/11/customize-the-contextual-menu-of-uiwebview/

let kNotificationMainWindowTapAndHold = "kNotificationMainWindowTapAndHold"

class BraveMainWindow : UIWindow {
    var tapLocation: CGPoint = CGPointZero
    var contextualMenuTimer: NSTimer = NSTimer()
    var tappedElement: ContextMenuHelper.Elements?

    lazy var contextMenuJs:String = {
        let path = NSBundle.mainBundle().pathForResource("BraveContextMenu", ofType: "js")!
        let source = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
        return source
    }()

    func resetTimer() {
        contextualMenuTimer.invalidate()
        tappedElement = nil
    }

    override func sendEvent(event: UIEvent) {
        super.sendEvent(event)

        guard let braveTopVC = getApp().rootViewController.visibleViewController as? BraveTopViewController else { return }

        //   print("\(event.touchesForWindow(self))")
        if let touches = event.touchesForWindow(self), let touch = touches.first where touches.count == 1 {
            braveTopVC.specialTouchEventHandling(touch.locationInView(self), phase: touch.phase)
            switch touch.phase {
            case .Began:  // A finger touched the screen
                tapLocation = touch.locationInView(self)
                resetTimer()
                // This timer repeats in order to run twice. See tapAndHoldAction() for comments.
                contextualMenuTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: "tapAndHoldAction", userInfo: nil, repeats: true)
                break
            case .Moved, .Stationary:
                let p1 = touch.locationInView(self)
                let p2 = touch.previousLocationInView(self)
                let distance =  hypotf(Float(p1.x) - Float(p2.x), Float(p1.y) - Float(p2.y))
                if distance > 1.0 {
                    resetTimer()
                }
                break
            case .Ended, .Cancelled:
                resetTimer()
                break
            }
        } else {
            resetTimer()
        }
    }

    func windowSizeAndScrollOffset(webView: BraveWebView) ->(CGSize, CGPoint)? {
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

    // This is called 2x, once at .25 seconds to ensure the native context menu is cancelled,
    // then again at .5 seconds to show our context menu.
    func tapAndHoldAction() {
        if let tappedElement = tappedElement {
            let info = ["point": NSValue(CGPoint: tapLocation)]
            NSNotificationCenter.defaultCenter().postNotificationName(kNotificationMainWindowTapAndHold, object: self, userInfo: info)
            guard let bvc = getApp().browserViewController else { return }
            bvc.showContextMenu(elements: tappedElement, touchPoint: tapLocation)
            resetTimer()
            return
        }

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
                let image = json["imagesrc"] as? String
                let url = json["link"] as? String
                return ContextMenuHelper.Elements(link: url != nil ? NSURL(string: url!) : nil, image: image != nil ? NSURL(string: image!) : nil)
            } catch {}
            return nil
        }

        tappedElement = responseToElement(response)
        
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
    }
}