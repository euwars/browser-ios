import Foundation
import WebKit
import Shared

func configureActiveCrashReporter(_:Bool?) {}

func convertNavActionToWKType(type:UIWebViewNavigationType) -> WKNavigationType {
  return WKNavigationType(rawValue: type.rawValue)!
}

class ContainerWebView : WKWebView {
  weak var legacyWebView: LegacyWebView?
}

var nullWebView: WKWebView = WKWebView()
var nullWKNavigation: WKNavigation = WKNavigation()

enum KVOStrings: String {
  case kvoCanGoBack = "canGoBack"
  case kvoCanGoForward = "canGoForward"
  case kvoLoading = "loading"
  case kvoURL = "URL"
  case kvoEstimatedProgress = "estimatedProgress"

  static let allValues = [kvoCanGoBack, kvoCanGoForward, kvoLoading, kvoURL, kvoEstimatedProgress]
}

class LegacyWebView: UIWebView {
  static let kNotificationWebViewLoadCompleteOrFailed = "kNotificationWebViewLoadCompleteOrFailed"
  static let kContextMenuBlockNavigation = 8675309
  lazy var configuration: LegacyWebViewConfiguration = { return LegacyWebViewConfiguration(webView: self) }()
  weak var navigationDelegate: WKNavigationDelegate?
  weak var UIDelegate: WKUIDelegate?
  lazy var backForwardList: LegacyBackForwardList = { return LegacyBackForwardList(webView: self) } ()
  var estimatedProgress: Double = 0
  var title: String = ""
  lazy var progress: LegacyWebViewProgress = { return LegacyWebViewProgress(parent: self) }()
  lazy var webViewDelegate: WebViewDelegate = { return WebViewDelegate(parent: self) }()
  var URL: NSURL?
  var internalIsLoadingEndedFlag: Bool = false;
  var knownFrameContexts = Set<NSObject>()

  // To mimic WKWebView we need this property. And, to easily overrride where Firefox code is setting it, we hack the setter,
  // so that a custom agent is set always to our kDesktopUserAgent.
  // A nil customUserAgent means to use the default which is correct.
  //TODO setting the desktop agent doesn't currently work, see note below)
  var customUserAgent:String? {
    willSet {
      if self.customUserAgent == newValue || newValue == nil {
        return
      }
      self.customUserAgent = newValue == nil ? nil : kDesktopUserAgent
      // The following doesn't work, we need to kill and restart the webview, and restore its history state
      // for this setting to take effect
      //      let defaults = NSUserDefaults(suiteName: AppInfo.sharedContainerIdentifier())!
      //      defaults.registerDefaults(["UserAgent": (self.customUserAgent ?? "")])
    }
  }

  override init(frame: CGRect) {
    #if DEBUG
      // TODO move to better spot, these quiet the logging from the core of fx ios
      GCDWebServer.setLogLevel(5)
      Logger.syncLogger.setup(.None)
      Logger.browserLogger.setup(.None)

      // desktop UA for testing
//      let defaults = NSUserDefaults(suiteName: AppInfo.sharedContainerIdentifier())!
//      let desktop = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; it-it) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16"
//      defaults.registerDefaults(["UserAgent": desktop])
    #endif

    super.init(frame: frame)
    delegate = self.webViewDelegate
    scalesPageToFit = true
    let selectorName = String(format: "_%@WebThread:", "setDrawIn") // avoid Apple Store static analyzer
    performSelector(NSSelectorFromString(selectorName), withObject:Bool(true))
    scrollView.decelerationRate = BraveUX.IsHighLoadAnimationAllowed ? UIScrollViewDecelerationRateNormal :UIScrollViewDecelerationRateFast
    setupSwipeGesture()
  }

  override var loading: Bool {
    get {
      if internalIsLoadingEndedFlag {
        // we detected load complete internally –UIWebView sometimes stays in a loading state (i.e. bbc.com)
        return false
      }
      return super.loading
    }
  }

  required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }

  override func loadRequest(request: NSURLRequest) {
    URL = request.URL
    super.loadRequest(request)
  }

  func kvoBroadcast(kvos: [KVOStrings]? = nil) {
    if let _kvos = kvos {
      for item in _kvos {
        willChangeValueForKey(item.rawValue)
        didChangeValueForKey(item.rawValue)
      }
    } else {
      // send all
      kvoBroadcast(KVOStrings.allValues)
    }
  }

  func setScalesPageToFit(setPages: Bool!) {
    self.scalesPageToFit = setPages
  }

  func canNavigateBackward() -> Bool {
    return self.canGoBack
  }

  func canNavigateForward() -> Bool {
    return self.canGoForward
  }

  func reloadFromOrigin() {
    self.reload()
  }

  private func convertStringToDictionary(text: String?) -> [String:AnyObject]? {
    if let data = text?.dataUsingEncoding(NSUTF8StringEncoding) where text?.characters.count > 0 {
      do {
        let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
        return json
      } catch {
        print("Something went wrong")
      }
    }
    return nil
  }

  func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
    let wrapped = "var result = \(javaScriptString); JSON.stringify(result)"
    let string = stringByEvaluatingJavaScriptFromString(wrapped)
    let dict = convertStringToDictionary(string)
    completionHandler?(dict, NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: nil))
  }

  func goToBackForwardListItem(item: LegacyBackForwardListItem) {
    if let index = backForwardList.backList.indexOf(item) {
      let backCount = backForwardList.backList.count - index
      for _ in 0..<backCount {
        goBack()
      }
    } else if let index = backForwardList.forwardList.indexOf(item) {
      for _ in 0..<(index + 1) {
        goForward()
      }
    }
  }

  override func goBack() {
    // stop scrolling so the web view will respond faster
    scrollView.setContentOffset(scrollView.contentOffset, animated: false)
    super.goBack()
  }

  override func goForward() {
    scrollView.setContentOffset(scrollView.contentOffset, animated: false)
    super.goForward()
  }

  class func isTopFrameRequest(request:NSURLRequest) -> Bool {
    return request.URL == request.mainDocumentURL
  }

  func setupSwipeGesture() {
    let right = UISwipeGestureRecognizer(target: self, action: "swipeRight:")
    right.direction = .Right
    let left = UISwipeGestureRecognizer(target: self, action: "swipeLeft:")
    left.direction = .Left

    left.requireGestureRecognizerToFail(right)
    right.requireGestureRecognizerToFail(left)

    addGestureRecognizer(right)
    addGestureRecognizer(left)
  }

  @objc func swipeRight(gesture: UISwipeGestureRecognizer) {
    if canGoBack {
      goBack()
    }
  }

  @objc func swipeLeft(gesture: UISwipeGestureRecognizer) {
    if canGoForward {
      goForward()
    }
  }

  // Long press context menu text selection overriding
  override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
    if (action.description.lowercaseString.contains("define")) {
      // This action leads to searching in Safari
      // TODO replace with an action that keeps the search in our app
      return false
    }
    return super.canPerformAction(action, withSender: sender)
  }
}

class WebViewDelegate: NSObject, UIWebViewDelegate {
  weak var parent:LegacyWebView?

  class LegacyNavigationAction : WKNavigationAction {
    var writableRequest: NSURLRequest
    var writableType: WKNavigationType

    init(type: WKNavigationType, request: NSURLRequest) {
      writableType = type
      writableRequest = request
      super.init()
    }

    override var request: NSURLRequest { get { return writableRequest} }
    override var navigationType: WKNavigationType { get { return writableType } }
    override var sourceFrame: WKFrameInfo {
      get { return WKFrameInfo() }
    }
  }

  init(parent: LegacyWebView) {
    self.parent = parent
  }

  func webView(webView: UIWebView,shouldStartLoadWithRequest request: NSURLRequest,
    navigationType: UIWebViewNavigationType ) -> Bool {
      guard let _parent = parent else { return false }

      if let contextMenu = _parent.window?.rootViewController?.presentedViewController
        where contextMenu.view.tag == LegacyWebView.kContextMenuBlockNavigation {
        // When showing a context menu, the webview will often still navigate (ex. news.google.com)
        // We need to block navigation using this tag. 
        return false
      }


      var result = _parent.progress.shouldStartLoadWithRequest(request, navigationType: navigationType)
      if !result {
        return false
      }

      if let nd = _parent.navigationDelegate {
        let action:LegacyNavigationAction =
        LegacyNavigationAction(type: convertNavActionToWKType(navigationType), request: request)

        nd.webView?(nullWebView, decidePolicyForNavigationAction: action,
          decisionHandler: { (policy:WKNavigationActionPolicy) -> Void in
            result = policy == .Allow
        })
      }

      let locationChanged = LegacyWebView.isTopFrameRequest(request)
      if locationChanged && (navigationType == .LinkClicked || navigationType == .Other) {
        _parent.URL = request.URL
      }

      _parent.kvoBroadcast()
      return result
  }


  func webViewDidStartLoad(webView: UIWebView) {
    parent?.backForwardList.update(webView)

    if let nd = parent?.navigationDelegate {
      nd.webView?(nullWebView, didStartProvisionalNavigation: nullWKNavigation)
    }
    parent?.progress.webViewDidStartLoad()
    parent?.kvoBroadcast([KVOStrings.kvoLoading])
  }

  func webViewDidFinishLoad(webView: UIWebView) {
    assert(NSThread.isMainThread())

    guard let _parent = parent else { return }
    let readyState = _parent.stringByEvaluatingJavaScriptFromString("document.readyState")?.lowercaseString

    _parent.progress.webViewDidFinishLoad(documentReadyState: readyState)

    _parent.title = webView.stringByEvaluatingJavaScriptFromString("document.title") ?? ""
    if let item = _parent.backForwardList.currentItem {
      item.title = _parent.title
    }

    if let scrapedUrl = webView.stringByEvaluatingJavaScriptFromString("window.location.href") {
      if !_parent.progress.pathContainsCompleted(scrapedUrl) {
        _parent.URL = NSURL(string: scrapedUrl)
        if let item = _parent.backForwardList.currentItem {
          item.URL = _parent.URL ?? item.URL
        }
      }
    }

    if (!webView.loading) {
      _parent.configuration.userContentController.injectJsIntoPage()
      // Stop built-in context menu
      LegacyUserContentController.injectJsIntoAllFrames(_parent, script: "document.body.style.webkitTouchCallout='none'")
      _parent.replaceImagesUsingTheVault(webView)
    }

    _parent.kvoBroadcast()

    // For testing
    if readyState == "complete" {
      NSNotificationCenter.defaultCenter()
        .postNotificationName(LegacyWebView.kNotificationWebViewLoadCompleteOrFailed, object: nil)

    }
  }

  func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
    if (error?.code == NSURLErrorCancelled) {
      return
    }
    NSNotificationCenter.defaultCenter()
      .postNotificationName(LegacyWebView.kNotificationWebViewLoadCompleteOrFailed, object: nil)
    if let nd = parent?.navigationDelegate {
      nd.webView?(nullWebView, didFailNavigation: nullWKNavigation,
        withError: error ?? NSError.init(domain: "", code: 0, userInfo: nil))
    }
    print("\(error)")
    parent?.progress.didFailLoadWithError()
    parent?.kvoBroadcast()
  }
}
