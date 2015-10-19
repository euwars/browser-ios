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

enum KVOStrings: String {
  case kvoCanGoBack = "canGoBack"
  case kvoCanGoForward = "canGoForward"
  case kvoLoading = "loading"
  case kvoURL = "url"
  case kvoEstimatedProgress = "estimatedProgress"

  static let allValues = [kvoCanGoBack, kvoCanGoForward, kvoLoading, kvoURL, kvoEstimatedProgress]
}

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

        let locationChanged = request.URL != request.mainDocumentURL;
        if (locationChanged && navigationType == .LinkClicked || navigationType == .Other) {
          let item:LegacyBackForwardListItem = LegacyBackForwardListItem()
          item.writableUrl = request.URL
          item.writableInitialUrl = request.URL
          //tem.writableSetTitle("to do");
          parent.backForwardList.pushItem(item)
        }

        kvoBroadcast(nil);

        parent.title = "Fill me in"

        return result;
    }

    func webViewDidStartLoad(webView: UIWebView) {
      if let nd = parent.navigationDelegate {
        nd.webView?(nullWebView, didStartProvisionalNavigation: nullWKNavigation)
      }
      kvoBroadcast([KVOStrings.kvoLoading]);
    }

    func webViewDidFinishLoad(webView: UIWebView) {
      if let nd = parent.navigationDelegate {
        nd.webView?(nullWebView, didFinishNavigation: nullWKNavigation)
      }
      kvoBroadcast(nil);
    }

    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
      if let nd = parent.navigationDelegate {
        nd.webView?(nullWebView, didFailNavigation: nullWKNavigation,
          withError: error ?? NSError.init(domain: "", code: 0, userInfo: nil))
      }
      kvoBroadcast(nil);
    }

    func kvoBroadcast(kvos: [KVOStrings]?) {
      if let _kvos = kvos {
        for item in _kvos {
          parent.willChangeValueForKey(item.rawValue)
          parent.didChangeValueForKey(item.rawValue)
        }
      } else {
        // send all
        kvoBroadcast(KVOStrings.allValues)
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
    assert(false);
  }

  override func goBack() {
    super.goBack()
    self.backForwardList.goBack()
  }

  override func goForward() {
    super.goForward()
    self.backForwardList.goForward()
  }

}
