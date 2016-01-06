/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class LegacyBackForwardListItem {

    var URL: NSURL = NSURL()
    var initialURL: NSURL = NSURL()
    var title:String = ""

    init(url: NSURL) {
        URL = url
        // In order to mimic the built-in API somewhat, the initial url is stripped of mobile site
        // parts of the host (mobile.nytimes.com -> initial url is nytimes.com). The initial url
        // is the pre-page-forwarding url
        let normal = url.scheme + "://" + (url.normalizedHostAndPath() ?? url.absoluteString)
        initialURL = NSURL(string: normal) ?? url
    }
}

extension LegacyBackForwardListItem: Equatable {}
func == (lhs: LegacyBackForwardListItem, rhs: LegacyBackForwardListItem) -> Bool {
    return lhs.URL.absoluteString == rhs.URL.absoluteString;
}


class WebViewBackForwardList {

    var currentIndex: Int = 0
    var backForwardList: [LegacyBackForwardListItem] = []
    weak var webView: BraveWebView?

    init(webView: BraveWebView) {
        self.webView = webView
    }

    var cachedHistoryStringLength = 0

    private func isSpecial(_url: NSURL?) -> Bool {
        guard let url = _url else { return false }
        return url.absoluteString.rangeOfString(WebServer.sharedInstance.base) != nil
    }

    func update(webview: UIWebView) {
        backForwardList = []
        guard let obj = webview.valueForKeyPath("documentView.webView.backForwardList") else { return }
        let history = obj.description
        let nsHistory = history as NSString

        if cachedHistoryStringLength > 0 &&
            cachedHistoryStringLength == nsHistory.length {
                return;
        }
        cachedHistoryStringLength = nsHistory.length

        let regex = try! NSRegularExpression(pattern:"\\d+\\) +<WebHistoryItem.+> (http.+) ", options: [])
        let result = regex.matchesInString(history, options: [], range: NSMakeRange(0, history.characters.count))
        var i = 0
        var foundCurrent = false
        for match in result {
            guard let url = NSURL(string: nsHistory.substringWithRange(match.rangeAtIndex(1))) else { continue }
            let item = LegacyBackForwardListItem(url: url)
            backForwardList.append(item)

            let currIndicator = ">>>"
            let rangeStart = match.range.location - currIndicator.characters.count
            if rangeStart > -1 &&
                nsHistory.substringWithRange(NSMakeRange(match.range.location - 4, 3)) == currIndicator {
                    currentIndex = i
                    foundCurrent = true
            }
            i++
        }
        if !foundCurrent {
            currentIndex = 0
        }
    }

    var currentItem: LegacyBackForwardListItem? {
        get {
            guard let item = itemAtIndex(currentIndex) else {
                if let url = webView?.URL {
                    let item = LegacyBackForwardListItem(url: url)
                    return item
                } else {
                    return nil
                }
            }
            return item

        }}

    var backItem: LegacyBackForwardListItem? {
        get {
            return itemAtIndex(currentIndex - 1)
        }}

    var forwardItem: LegacyBackForwardListItem? {
        get {
            return itemAtIndex(currentIndex + 1)
        }}

    func itemAtIndex(index: Int) -> LegacyBackForwardListItem? {
        if (backForwardList.count == 0 ||
            index > backForwardList.count - 1 ||
            index < 0) {
                return nil
        }
        return backForwardList[index]
    }
    
    var backList: [LegacyBackForwardListItem] {
        get {
            return (currentIndex > 0 && backForwardList.count > 0) ? Array(backForwardList[0..<currentIndex]) : []
        }}
    
    var forwardList: [LegacyBackForwardListItem] {
        get {
            return (currentIndex + 1 < backForwardList.count  && backForwardList.count > 0) ?
                Array(backForwardList[(currentIndex + 1)..<backForwardList.count]) : []
        }}
}