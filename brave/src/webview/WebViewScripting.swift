/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

func hashString (obj: AnyObject) -> String {
    return String(ObjectIdentifier(obj).uintValue)
}


class LegacyUserContentController
{
    var scriptHandlersMainFrame = [String:WKScriptMessageHandler]()
    var scriptHandlersSubFrames = [String:WKScriptMessageHandler]()
    let whitelistSubFrameScripts = ["contextMenuMessageHandler"]
    var scripts:[WKUserScript] = []
    weak var webView: BraveWebView?

    func addScriptMessageHandler(scriptMessageHandler: WKScriptMessageHandler, name: String) {
        scriptHandlersMainFrame[name] = scriptMessageHandler

        if hasWhitelistedSubFrameHandlerInString(name) {
            scriptHandlersSubFrames[name] = scriptMessageHandler
        }
    }

    func hasWhitelistedSubFrameHandlerInString(script: String) -> Bool {
        return whitelistSubFrameScripts.filter({ script.contains($0) }).count > 0
    }

    func addUserScript(script:WKUserScript) {
        var mainFrameOnly = true
        if !script.forMainFrameOnly && hasWhitelistedSubFrameHandlerInString(script.source) {
            // Only contextMenu injection to subframes for now,
            // whitelist this explicitly, don't just inject scripts willy-nilly into frames without
            // careful consideration. For instance, there are security implications with password management in frames
            mainFrameOnly = false
        }
        scripts.append(WKUserScript(source: script.source, injectionTime: script.injectionTime, forMainFrameOnly: mainFrameOnly))
    }

    init(_ webView: BraveWebView) {
        self.webView = webView
    }

    func injectIntoMain() {
        guard let webView = webView else { return }

        let result = webView.stringByEvaluatingJavaScriptFromString("Window.prototype.webkit.hasOwnProperty('messageHandlers')")
        if result == "true" {
            // already injected into this context
            return
        }

        let js = LegacyJSContext()
        for (name, handler) in scriptHandlersMainFrame {
            if !name.lowercaseString.contains("reader") {
                js.installHandlerForWebView(webView, handlerName: name, handler:handler)
            }
        }

        for script in scripts {
            webView.stringByEvaluatingJavaScriptFromString(script.source)
        }
    }

    func injectIntoSubFrame() {
        let js = LegacyJSContext()
        let contexts = js.findNewFramesForWebView(webView, withFrameContexts: webView?.knownFrameContexts)

        for ctx in contexts {
            webView?.knownFrameContexts.insert(ctx.hash)

            for (name, handler) in scriptHandlersSubFrames {
                js.installHandlerForContext(ctx, handlerName: name, handler:handler, webView:webView)
            }
            for script in scripts {
                if !script.forMainFrameOnly {
                    js.callOnContext(ctx, script: script.source)
                }
            }
        }
    }

    static func injectJsIntoAllFrames(webView: BraveWebView, script: String) {
        webView.stringByEvaluatingJavaScriptFromString(script)
        let js = LegacyJSContext()
        let contexts = js.findNewFramesForWebView(webView, withFrameContexts: webView.knownFrameContexts)

        for ctx in contexts {
            webView.knownFrameContexts.insert(ctx.hash)
            js.callOnContext(ctx, script: script)
        }
    }
    
    func injectJsIntoPage() {
        injectIntoMain()
        injectIntoSubFrame()
    }
}

class BraveWebViewConfiguration
{
    let userContentController: LegacyUserContentController
    init(webView: BraveWebView) {
        userContentController = LegacyUserContentController(webView)
    }
}
