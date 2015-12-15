/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

let kNotificationPageUnload = "kNotificationPageUnload"

class BravePageUnloadHelper: NSObject, BrowserHelper {
  private weak var browser: Browser?
  weak var delegate: ContextMenuHelperDelegate?

  class func name() -> String {
    return "PageUnloadHelper"
  }

  required init(browser: Browser) {
    super.init()

    self.browser = browser

    let path = NSBundle.mainBundle().pathForResource("PageUnload", ofType: "js")!
    let source = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
    let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
    browser.webView!.configuration.userContentController.addUserScript(userScript)
  }

  func scriptMessageHandlerName() -> String? {
    return "pageUnloadMessageHandler"
  }

  func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {

    //guard let data = message.body as? [String: AnyObject] else { return }
    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationPageUnload, object: browser?.webView)
  }
}