import Foundation

// (echo 'let easyList = "' && cat orig | sed 's|\\|\\\\|g' | sed 's|\"|\\"|g' |sed 's|$|\\n|' |tr '\n' ' ' && echo '"') > easylist-as-string.swift

private let singleton = AdBlocker()

class AdBlocker {

  private init() {
  }

  class var singleton: AdBlocker {
    return _sharedInstance
  }
}