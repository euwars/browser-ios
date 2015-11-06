import Foundation



func hashString (obj: AnyObject) -> String {
  return String(ObjectIdentifier(obj).uintValue)
}


class LegacyUserContentController
{
  var scriptHandlersMainFrame = [String:WKScriptMessageHandler]()
  var scriptHandlersSubFrames = [String:WKScriptMessageHandler]()
  var scripts:[WKUserScript] = []
  weak var webView: LegacyWebView?

  func addScriptMessageHandler(scriptMessageHandler: WKScriptMessageHandler, name: String) {
    scriptHandlersMainFrame[name] = scriptMessageHandler

    if name.contains("contextMenu") {
      scriptHandlersSubFrames[name] = scriptMessageHandler
    }
  }

  func addUserScript(script:WKUserScript) {
    var mainFrameOnly = true
    if !script.forMainFrameOnly && script.source.contains("contextMenuMessageHandler") {
      // Only contextMenu injection to subframes for now,
      // whitelist this explicitly, don't just inject scripts willy-nilly into frames without
      // careful consideration. For instance, there are security implications with password management in frames
      mainFrameOnly = false
    }
    scripts.append(WKUserScript(source: script.source, injectionTime: script.injectionTime, forMainFrameOnly: mainFrameOnly))
  }

  init(_ webView: LegacyWebView) {
    self.webView = webView

   /// crashy
    //// NSNotificationCenter.defaultCenter().addObserver(self, selector: "notificationFrameCreated:", name: "frame for webview \(webView.uuid)", object: nil)
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
      js.installHandlerForWebView(webView, handlerName: name, handler:handler)
    }

    for script in scripts {
      webView.stringByEvaluatingJavaScriptFromString(script.source)
    }
  }

  @objc func notificationFrameCreated(/*notification: NSNotification*/) {
//    let ctx = notification.userInfo?["context"]
//    assert(ctx != nil)
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
}

class LegacyWebViewConfiguration
{
  let userContentController: LegacyUserContentController
  init(webView: LegacyWebView) {
    userContentController = LegacyUserContentController(webView)
  }
}
