import Foundation

class LegacyBackForwardListItem  {

  var URL: NSURL = NSURL()
  var initialURL: NSURL = NSURL()
  var title:String = ""
}

class LegacyBackForwardList {

  var currentIndex: Int = 0
  var writableForwardBackList: [LegacyBackForwardListItem] = []

  func goBack() {
    if currentIndex > 0 {
      self.currentIndex--
    }
  }

  func goForward() {
    if currentIndex < (writableForwardBackList.count - 1) {
      self.currentIndex++
    }
  }

  func pushItem(item: LegacyBackForwardListItem) {
    if (writableForwardBackList.count - 1) > currentIndex {
      if let current = currentItem {
        writableForwardBackList = backList
        writableForwardBackList.append(current)
      }
    }
    writableForwardBackList.append(item)
    currentIndex = writableForwardBackList.count - 1
    print("bf count \(writableForwardBackList.count), current index: \(currentIndex)  #########################################")
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
      if (writableForwardBackList.count == 0 ||
          index > writableForwardBackList.count - 1 ||
          index < 0) {
        return nil
      }
      return writableForwardBackList[index]
    }

  var backList: [LegacyBackForwardListItem] {
    get {
      return (currentIndex > 0) ? Array(writableForwardBackList[0..<currentIndex]) : []
    }}

  var forwardList: [LegacyBackForwardListItem] {
    get {
      return (currentIndex + 1 < writableForwardBackList.count) ?
              Array(writableForwardBackList[(currentIndex + 1)..<writableForwardBackList.count]) : []
    }}
}