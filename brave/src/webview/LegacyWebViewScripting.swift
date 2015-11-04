import Foundation



func hashString (obj: AnyObject) -> String {
  return String(ObjectIdentifier(obj).uintValue)
}


class LegacyUserContentController
{
  var scriptHandlers = [String:WKScriptMessageHandler]()

  var scripts:[WKUserScript] = []
  weak var webView: LegacyWebView?

  func addScriptMessageHandler(scriptMessageHandler: WKScriptMessageHandler, name: String) {
    scriptHandlers[name] = scriptMessageHandler
  }

  func addUserScript(script:WKUserScript) {
    scripts.append(script)
  }

  init(_ webView: LegacyWebView) {
    self.webView = webView
  }

  func inject() {
    let js = LegacyJSContext()

    guard let web = webView else { return }

    for (name, handler) in scriptHandlers {
      js.installHandlerForWebView(web, handlerName: name, handler:handler)
    }

    for script in scripts {
      webView?.stringByEvaluatingJavaScriptFromString(script.source)
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
