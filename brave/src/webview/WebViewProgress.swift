/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Based on  https://github.com/ninjinkun/NJKWebViewProgress
// MIT License https://github.com/ninjinkun/NJKWebViewProgress/blob/master/LICENSE

import Foundation

let completedUrlPath: String = "__completedprogress__"

public class WebViewProgress
{
    var loadingCount: Int = 0;
    var maxLoadCount: Int = 0;
    var interactive: Bool = false;

    let initialProgressValue: Double = 0.1;
    let interactiveProgressValue: Double = 0.5;
    let finalProgressValue: Double = 0.9;

    weak var webView: BraveWebView?;
    var currentURL: NSURL?;

    /* After all efforts to catch page load completion in WebViewProgress, sometimes, load completion is *still* missed.
    As a backup we can do KVO on 'loading'. Which can arrive too early (from subrequests) -and frequently- so delay checking by an arbitrary amount
    using a timer. The only problem with this is that there is yet more code for load detection, sigh.
    TODO figure this out. http://thestar.com exhibits this sometimes.
    Possibly a bug in UIWebView with load completion, but hard to repro, a reload of a page always seems to complete. */
    private class LoadingObserver : NSObject {
        private let webView: BraveWebView
        private var timer: NSTimer?

        init(webView:BraveWebView) {
            self.webView = webView
            super.init()
            webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
        }

        @objc func delayedCompletionCheck() {
            if webView.loading || webView.estimatedProgress > 0.99 {
                return
            }

            let readyState = webView.stringByEvaluatingJavaScriptFromString("document.readyState")?.lowercaseString
            if readyState == "loaded" || readyState == "complete" {
                webView.progress.completeProgress()
            }
        }

        @objc override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
            if let path = keyPath where path == "loading" {
                if !webView.loading && webView.estimatedProgress < 1.0 {
                    timer?.invalidate()
                    timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "delayedCompletionCheck", userInfo: nil, repeats: false)
                } else {
                    timer?.invalidate()
                }
            }
        }
    }
    private var loadingObserver: LoadingObserver?

    init(parent: BraveWebView) {
        webView = parent
        currentURL = parent.request?.URL
        loadingObserver = LoadingObserver(webView: parent)
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

        func injectLoadDetection() {
            if let scheme = webView?.request?.mainDocumentURL?.scheme,
                host = webView?.request?.mainDocumentURL?.host
            {
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
        }

        injectLoadDetection()
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
                interactive = true
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