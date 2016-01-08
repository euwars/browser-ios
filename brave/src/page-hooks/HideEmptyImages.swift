/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class HideEmptyImages {
    static var source: String?
    init(webView: BraveWebView) {
        if (HideEmptyImages.source == nil) {
            let path = NSBundle.mainBundle().pathForResource("HideEmptyImages", ofType: "js")!
            HideEmptyImages.source = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
        }
        if let source = HideEmptyImages.source {
            webView.stringByEvaluatingJavaScriptFromString(source)
        }
    }
}