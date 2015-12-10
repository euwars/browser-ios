// Based on  https://github.com/ninjinkun/NJKWebViewProgress
// MIT License https://github.com/ninjinkun/NJKWebViewProgress/blob/master/LICENSE

import Foundation

let completedUrlPath: String = "__completedprogress__"
let initialProgressValue: Double = 0.1;
let interactiveProgressValue: Double = 0.5;
let finalProgressValue: Double = 0.9;

public class LegacyWebViewProgress
{
  var _loadingCount: Int = 0;
  var _maxLoadCount: Int = 0;
  var _interactive: Bool = false;

  weak var webView: LegacyWebView?;
  var _currentURL: NSURL?;

  init(parent: LegacyWebView) {
    webView = parent
    _currentURL = webView?.request?.URL
  }

  func setProgress(progress: Double) {
    if (progress > webView?.estimatedProgress || progress == 0 || progress > 0.99) {
      webView?.estimatedProgress = progress;
      webView?.kvoBroadcast()
    }
  }

  func startProgress() {
    if (webView?.estimatedProgress < initialProgressValue) {
      setProgress(initialProgressValue);
    }
  }

  func incrementProgress() {
    var progress = webView?.estimatedProgress ?? 0.0
    let maxProgress = _interactive ? finalProgressValue : interactiveProgressValue
    let remainPercent = Double(_loadingCount) / Double(_maxLoadCount)
    let increment = (maxProgress - progress) * remainPercent
    progress += increment
    progress = fmin(progress, maxProgress)
    setProgress(progress)
  }

  func completeProgress() {
    if let nd = webView?.navigationDelegate {
      let container = ContainerWebView()
      container.legacyWebView = webView
      nd.webView?(container, didFinishNavigation: nullWKNavigation)
    }

    webView?.internalIsLoadingEndedFlag = true
    setProgress(1.0)
  }

  public func reset() {
    _maxLoadCount = 0
    _loadingCount = 0
    _interactive = false
    setProgress(0.0)
    webView?.internalIsLoadingEndedFlag = false
  }

  public func pathContainsCompleted(path: String?) -> Bool {
    return path?.rangeOfString(completedUrlPath) != nil
  }

  public func shouldStartLoadWithRequest(request: NSURLRequest, navigationType:UIWebViewNavigationType) ->Bool {
    if (pathContainsCompleted(request.URL?.fragment)) {
      completeProgress()
      return false
    }

    var isFragmentJump: Bool = false
    
    if let fragment = request.URL?.fragment {
      let nonFragmentUrl = request.URL?.absoluteString.stringByReplacingOccurrencesOfString("#" + fragment,
        withString: "")

      isFragmentJump = nonFragmentUrl == webView?.request?.URL?.absoluteString
    }

    let isTopLevelNavigation = request.mainDocumentURL == request.URL

    let isHTTPOrLocalFile = request.URL?.scheme.startsWith("http") == true ||
      request.URL?.scheme.startsWith("file") == true

    if (!isFragmentJump && isHTTPOrLocalFile && isTopLevelNavigation) {
      _currentURL = request.URL
      reset()
    }
    return true
  }

  public func webViewDidStartLoad() {
    _loadingCount++
    _maxLoadCount = max(_maxLoadCount, _loadingCount)
    startProgress()
  }

  public func webViewDidFinishLoad(documentReadyState documentReadyState:String?) {
    _loadingCount--;
    incrementProgress()

    if let readyState = documentReadyState {
      switch readyState {
      case "loaded":
        completeProgress()
      case "interactive":
        if let scheme = webView?.request?.mainDocumentURL?.scheme,
            host = webView?.request?.mainDocumentURL?.host
        {
          _interactive = true
          let waitForCompleteJS = String(format:
            "window.addEventListener('load', function() {" +
                "var iframe = document.createElement('iframe');" +
                "iframe.style.display = 'none';" +
                "iframe.src = '%@://%@/#%@';" +
                "document.body.appendChild(iframe);" +
            "}, false);",
            scheme,
            host,
            completedUrlPath);
          webView?.stringByEvaluatingJavaScriptFromString(waitForCompleteJS)
        }
      case "complete":
        // When loading consecutive pages, I often see a finishLoad for the previous page
        // arriving. I have tried webview.stopLoading, and still this seems to arrive. Bizarre.
        let isMainDoc = _currentURL != nil && _currentURL == webView?.request?.mainDocumentURL
        if (isMainDoc) {
          completeProgress()
        }
        default: ()
      }
    }
  }

  public func didFailLoadWithError() {
    webViewDidFinishLoad(documentReadyState: nil)
  }
}