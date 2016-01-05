// Based on  https://github.com/ninjinkun/NJKWebViewProgress
// MIT License https://github.com/ninjinkun/NJKWebViewProgress/blob/master/LICENSE

import Foundation

let completedUrlPath: String = "__completedprogress__"
let initialProgressValue: Double = 0.1;
let interactiveProgressValue: Double = 0.5;
let finalProgressValue: Double = 0.9;

public class WebViewProgress
{
    var loadingCount: Int = 0;
    var maxLoadCount: Int = 0;
    var interactive: Bool = false;

    weak var webView: BraveWebView?;
    var currentURL: NSURL?;

    init(parent: BraveWebView) {
        webView = parent
        currentURL = webView?.request?.URL
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
        let maxProgress = interactive ? finalProgressValue : interactiveProgressValue
        let remainPercent = Double(loadingCount) / Double(maxLoadCount)
        let increment = (maxProgress - progress) * remainPercent
        progress += increment
        progress = fmin(progress, maxProgress)
        setProgress(progress)
    }

    func completeProgress() {
        webView?.loadingCompleted()
        setProgress(1.0)
    }

    public func reset() {
        maxLoadCount = 0
        loadingCount = 0
        interactive = false
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
            currentURL = request.URL
            reset()
        }
        return true
    }

    public func webViewDidStartLoad() {
        loadingCount++
        maxLoadCount = max(maxLoadCount, loadingCount)
        startProgress()
    }

    public func webViewDidFinishLoad(documentReadyState documentReadyState:String?) {
        loadingCount--;
        incrementProgress()

        if webView?.loading == false {
            completeProgress()
            return
        }

        if let readyState = documentReadyState {
            switch readyState {
            case "loaded":
                completeProgress()
            case "interactive":
                if let scheme = webView?.request?.mainDocumentURL?.scheme,
                    host = webView?.request?.mainDocumentURL?.host
                {
                    interactive = true
                    let waitForCompleteJS = String(format:
                        "if (!__waitForCompleteJS__) {" +
                        "var __waitForCompleteJS__ = 1;" +
                        "window.addEventListener('load', function() {" +
                            "var iframe = document.createElement('iframe');" +
                            "iframe.style.display = 'none';" +
                            "iframe.src = '%@://%@/#%@';" +
                            "document.body.appendChild(iframe);" +
                        "}, false);}",
                        scheme,
                        host,
                        completedUrlPath);
                    webView?.stringByEvaluatingJavaScriptFromString(waitForCompleteJS)
                }
            case "complete":
                // When loading consecutive pages, I often see a finishLoad for the previous page
                // arriving. I have tried webview.stopLoading, and still this seems to arrive. Bizarre.
                let isMainDoc = currentURL != nil && currentURL == webView?.URL
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