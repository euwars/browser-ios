import Foundation
import WebKit

class LegacyScriptMessage: WKScriptMessage
{
  var writeableMessageBody: String = ""

  override var body: AnyObject {
    get {
      return writeableMessageBody;
    }
  }
}

class LegacyUserContentController
{
  var scriptHandlers:[WKScriptMessageHandler] = []

  func addScriptMessageHandler(scriptMessageHandler: WKScriptMessageHandler, name: String) {

    scriptHandlers.append(scriptMessageHandler)

    // do injection of script to frames

    let message:LegacyScriptMessage = LegacyScriptMessage()
    message.writeableMessageBody = "some response"
    for handler in self.scriptHandlers {
      handler.userContentController(WKUserContentController(), didReceiveScriptMessage: message);
    }
  }

  func addUserScript(script:WKUserScript) {
  }
}

class LegacyWebViewConfiguration
{
  var userContentController: LegacyUserContentController = LegacyUserContentController()
}

class LegacyBackForwardListItem: WKBackForwardListItem
{
  var writableURL:NSURL = NSURL(string: "http://0.0.0.0")!
  var writableTitle:String = ""
  var writableInitialURL:NSURL = NSURL(string: "http://0.0.0.0")!

  override var URL: NSURL { get { return writableURL} }
  override var title: String? { get {return writableTitle}}
  override var initialURL: NSURL { get {return writableInitialURL} }
}

class LegacyBackForwardList: WKBackForwardList {

  override var currentItem: WKBackForwardListItem? {
    get {
      return LegacyBackForwardListItem()
    }
  }

  override var backItem: WKBackForwardListItem? {
    get  {
      return LegacyBackForwardListItem()
    }}

  override var forwardItem: WKBackForwardListItem? { get  {
    return LegacyBackForwardListItem()
    }}

  override func itemAtIndex(index: Int) -> WKBackForwardListItem? {
    return LegacyBackForwardListItem()
  }

  override var backList: [WKBackForwardListItem] {
    get {
      return [LegacyBackForwardListItem]()
    }}

  override var forwardList: [WKBackForwardListItem] {
    get { return [LegacyBackForwardListItem]()}
  }
}
//
//class LegacyWebViewNavigationDelegate {
//
//   public func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void)
//   public func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void)
//   public func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!)
//
//   public func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!)
//
//   public func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError)
//   public func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!)
//
//   public func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!)
//   public func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError)
//
//   public func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)
//
//}

func convertNavActionToWKType(type:UIWebViewNavigationType) -> WKNavigationType {
  return WKNavigationType(rawValue: type.rawValue)!
}

var nullWebView:WKWebView = WKWebView()
var nullWKNavigation: WKNavigation = WKNavigation()

class LegacyWebView: UIWebView {

  var configuration:LegacyWebViewConfiguration = LegacyWebViewConfiguration()

  weak var navigationDelegate:WKNavigationDelegate?;
  weak var UIDelegate:WKUIDelegate?;

  var backForwardList:LegacyBackForwardList = LegacyBackForwardList();

  var estimatedProgress:Double = 0;

  var title:String = "";

  var URL:NSURL? {
    get {
     return self.request?.URL
    }
  }

  class WebViewDelegate: NSObject, UIWebViewDelegate {
    weak var parent:LegacyWebView! = nil;

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

    func webView(webView: UIWebView,shouldStartLoadWithRequest request: NSURLRequest,
      navigationType: UIWebViewNavigationType ) -> Bool {
        var result: Bool = true

        if let nd = parent.navigationDelegate {
          let action:LegacyNavigationAction =
            LegacyNavigationAction(type: convertNavActionToWKType(navigationType), request: request)

          nd.webView?(nullWebView, decidePolicyForNavigationAction: action,
            decisionHandler: { (policy:WKNavigationActionPolicy) -> Void in
              result = policy == .Allow
          })
        }
        kvoBroadcast();

        parent.title = "Fill me in"

        return result;
    }

    func webViewDidStartLoad(webView: UIWebView) {
      if let nd = parent.navigationDelegate {
        nd.webView?(nullWebView, didStartProvisionalNavigation: nullWKNavigation)
      }
      kvoBroadcast();
    }

    func webViewDidFinishLoad(webView: UIWebView) {
      if let nd = parent.navigationDelegate {
        nd.webView?(nullWebView, didFinishNavigation: nullWKNavigation)
      }
      kvoBroadcast();
    }

    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
      if let nd = parent.navigationDelegate {
        nd.webView?(nullWebView, didFailNavigation: nullWKNavigation,
          withError: error ?? NSError.init(domain: "", code: 0, userInfo: nil))
      }
      kvoBroadcast();
    }

    func kvoBroadcast() {
      let kvos:[String] = ["canGoBack", "canGoForward", "loading", "url", "estimatedProgress"]
      for item in kvos {
        parent.willChangeValueForKey(item)
        parent.didChangeValueForKey(item)
      }
    }
  }

  var webViewDelegate: WebViewDelegate = WebViewDelegate()

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.delegate = self.webViewDelegate
    self.webViewDelegate.parent = self
  }

  required init?(coder aDecoder: NSCoder) {
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
    
  }
}
