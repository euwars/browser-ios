import Foundation

class LegacyBackForwardListItem  {

  var URL: NSURL = NSURL()
  var initialURL: NSURL = NSURL()
  var title:String = ""
}

class LegacyBackForwardList {

  var currentIndex: Int = 0
  var backForwardList: [LegacyBackForwardListItem] = []

  func dump() {
    for i in backList {
      print("\(i.URL.absoluteString)")
    }
  }

  func goBack() {
    if currentIndex > 0 {
      self.currentIndex--
    }
    dump()
  }

  func goForward() {
    if currentIndex < (backForwardList.count - 1) {
      self.currentIndex++
    }
    dump()
  }

  private func isSpecial(_url: NSURL?) -> Bool {
    guard let url = _url else { return false }
    return url.absoluteString.rangeOfString(WebServer.sharedInstance.base) != nil
  }

  func push(_url: NSURL?) {
    guard let url = _url else { return }
    if (url.absoluteString.characters.count < 1 || currentItem?.URL.absoluteString == url.absoluteString) {
      return
    }

    // only one localhost entry allowed, just update the curent one
    if (isSpecial(_url) && isSpecial(currentItem?.URL)) {
      currentItem?.URL = url
      currentItem?.initialURL = url
      return
    }

    let item:LegacyBackForwardListItem = LegacyBackForwardListItem()
    item.URL = url
    item.initialURL = url
    pushItem(item)
  }

  func pushItem(item: LegacyBackForwardListItem) {
    if (backForwardList.count - 1) > currentIndex {
      if let current = currentItem {
        backForwardList = backList
        backForwardList.append(current)
      }
    }
    backForwardList.append(item)
    currentIndex = backForwardList.count - 1
    print("bf count \(backForwardList.count), current index: \(currentIndex) \(item.URL.absoluteString) ##########################")
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