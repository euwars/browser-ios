import Foundation

class LegacyBackForwardListItem  {

  var URL: NSURL = NSURL()
  var initialURL: NSURL = NSURL()
  var title:String = ""
}

class LegacyBackForwardList {

  var currentIndex: Int = 0
  var backForwardList: [LegacyBackForwardListItem] = []

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
      }
      i++
    }
  }

  var currentItem: LegacyBackForwardListItem? {
    get {
        return itemAtIndex(currentIndex)
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
      return (currentIndex > 0) ? Array(backForwardList[0..<currentIndex]) : []
    }}

  var forwardList: [LegacyBackForwardListItem] {
    get {
      return (currentIndex + 1 < backForwardList.count) ?
              Array(backForwardList[(currentIndex + 1)..<backForwardList.count]) : []
    }}
}