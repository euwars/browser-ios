import Foundation
import Shared
private let _singleton = AdBlocker()

class AdBlocker {

  private init() {
  }

  class var singleton: AdBlocker {
    return _singleton
  }

  func shouldBlock(request: NSURLRequest) -> Bool {
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let profile = appDelegate.getProfile(UIApplication.sharedApplication())
    if !(profile.prefs.boolForKey(AdBlockSetting.prefKey) ?? AdBlockSetting.defaultValue) {
      return false
    }

    guard let url = request.URL,
      domain = request.mainDocumentURL?.host else {
        return false
    }

    if let host = url.host where host.startsWith(domain) {
      return false
    }

    return AdBlockCppFilter.singleton().checkWithCppABPFilter(url.absoluteString, mainDocumentUrl: domain)
  }
}