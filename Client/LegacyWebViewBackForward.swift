import Foundation

class LegacyBackForwardListItem : WKBackForwardListItem {

  var writableUrl: NSURL?
  var writableInitialUrl: NSURL?
  var writableTitle: String?

  override var URL: NSURL {
    get {
      return writableUrl ?? NSURL()
    }}

  override var initialURL: NSURL {
    get {
      return writableInitialUrl ?? NSURL()
    }}

  override var title:String {
    get {
      return writableTitle ?? String()
    }}
}

class LegacyBackForwardList : WKBackForwardList {

  var currentIndex: Int = 0
  var writableForwardBackList: [LegacyBackForwardListItem] = []

  func goBack() {
    if (currentIndex > 0) {
      self.currentIndex--
    }
  }

  func goForward() {
    if (currentIndex < writableForwardBackList.count - 1) {
      self.currentIndex++
    }
  }

  func pushItem(item: LegacyBackForwardListItem) {
    if (writableForwardBackList.count - 1 > currentIndex + 1) {
      writableForwardBackList.removeRange((currentIndex + 1)..<writableForwardBackList.count)
    }
    writableForwardBackList.append(item)
    currentIndex = writableForwardBackList.count - 1
  }

  override var currentItem: WKBackForwardListItem? {
    get {
        return itemAtIndex(currentIndex)
    }}

  override var backItem: WKBackForwardListItem? {
    get {
      return itemAtIndex(currentIndex - 1)
    }}

  override var forwardItem: WKBackForwardListItem? {
    get {
      return itemAtIndex(currentIndex + 1)
    }}

  override func itemAtIndex(index: Int) -> WKBackForwardListItem? {
      if (writableForwardBackList.count == 0 ||
          index > writableForwardBackList.count - 1 ||
          index < 0) {
        return nil
      }
      return writableForwardBackList[index]
    }

  override var backList: [WKBackForwardListItem] {
    get {
      return (currentIndex > 0) ? Array(writableForwardBackList[0..<currentIndex]) : []
    }}

  override var forwardList: [WKBackForwardListItem] {
    get {
      return (currentIndex + 1 < writableForwardBackList.count) ?
              Array(writableForwardBackList[(currentIndex + 1)..<writableForwardBackList.count]) : []
    }}
}