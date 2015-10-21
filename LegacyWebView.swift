import Foundation
import WebKit



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

public class LegacyWebView: UIWebView {
  lazy var configuration: LegacyWebViewConfiguration = { return LegacyWebViewConfiguration(webview: self) }()
  weak var navigationDelegate: WKNavigationDelegate?;
  weak var UIDelegate: WKUIDelegate?;
  var backForwardList: LegacyBackForwardList = LegacyBackForwardList();
  var estimatedProgress: Double = 0;
  var title: String = "";
  lazy var progress: LegacyWebViewProgress = { return LegacyWebViewProgress(parent: self) }()
  lazy var webViewDelegate: WebViewDelegate = { return WebViewDelegate(parent: self) }()

  var URL: NSURL?;

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.delegate = self.webViewDelegate
  }

  public required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
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
    self.reload();
  }

  func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
    let string = stringByEvaluatingJavaScriptFromString(javaScriptString);
    completionHandler?(string, NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: nil))
  }

  func goToBackForwardListItem(item: WKBackForwardListItem) {
    assert(false);
  }

  override public func goBack() {
    super.goBack()
    self.backForwardList.goBack()
  }

  override public func goForward() {
    super.goForward()
    self.backForwardList.goForward()
  }

  class func isTopFrameRequest(request:NSURLRequest) -> Bool {
    return request.URL == request.mainDocumentURL
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
        let item:LegacyBackForwardListItem = LegacyBackForwardListItem()
        item.writableUrl = request.URL
        item.writableInitialUrl = request.URL
        ////////////item.writableTitle = "to do"
        _parent.backForwardList.pushItem(item)
        _parent.URL = request.URL;
      }

      kvoBroadcast(nil);
      return result;
  }


  func webViewDidStartLoad(webView: UIWebView) {
    if let nd = parent?.navigationDelegate {
      nd.webView?(nullWebView, didStartProvisionalNavigation: nullWKNavigation)
    }
    parent?.progress.webViewDidStartLoad()
    kvoBroadcast([KVOStrings.kvoLoading])
  }

  func webViewDidFinishLoad(webView: UIWebView) {
    if let nd = parent?.navigationDelegate {
      let container = ContainerWebView()
      container.legacyWebView = parent;
      nd.webView?(container, didFinishNavigation: nullWKNavigation)
    }

    guard let _parent = parent else { return }
    _parent.progress.webViewDidFinishLoad()

    _parent.title = webView.stringByEvaluatingJavaScriptFromString("document.title") ?? "";
    if let item = _parent.backForwardList.currentItem as? LegacyBackForwardListItem {
      item.writableTitle = _parent.title
    }

    if let scrapedUrl = webView.stringByEvaluatingJavaScriptFromString("window.location.href") {
      if !_parent.progress.pathContainsCompleted(scrapedUrl) {
        _parent.URL = NSURL(string: scrapedUrl)
        if let item = _parent.backForwardList.currentItem as? LegacyBackForwardListItem {
          item.writableUrl = _parent.URL
        }
      }
    }

    if (!webView.loading) {
      parent?.configuration.userContentController.inject()
    }

    kvoBroadcast(nil);
  }

  func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
    if let nd = parent?.navigationDelegate {
      nd.webView?(nullWebView, didFailNavigation: nullWKNavigation,
        withError: error ?? NSError.init(domain: "", code: 0, userInfo: nil))
    }
    parent?.progress.didFailLoadWithError()
    kvoBroadcast(nil);
  }

  func kvoBroadcast(kvos: [KVOStrings]?) {
    if let _kvos = kvos {
      for item in _kvos {
        parent?.willChangeValueForKey(item.rawValue)
        parent?.didChangeValueForKey(item.rawValue)
      }
    } else {
      // send all
      kvoBroadcast(KVOStrings.allValues)
    }
  }
}
