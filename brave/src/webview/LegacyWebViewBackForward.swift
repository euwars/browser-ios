import Foundation

class LegacyBackForwardListItem {

  var URL: NSURL = NSURL()
  var initialURL: NSURL = NSURL()
  var title:String = ""
}

extension LegacyBackForwardListItem: Equatable {}
func == (lhs: LegacyBackForwardListItem, rhs: LegacyBackForwardListItem) -> Bool {
  return lhs.URL.absoluteString == rhs.URL.absoluteString;
}


class LegacyBackForwardList {

  var currentIndex: Int = 0
  var backForwardList: [LegacyBackForwardListItem] = []
  weak var webView: LegacyWebView?

  init(webView: LegacyWebView) {
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
      let item = LegacyBackForwardListItem()
      item.URL = url
      item.initialURL = item.URL
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
        let item = LegacyBackForwardListItem()
        item.URL = url
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