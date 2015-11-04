import Foundation
import Shared
private let _singleton = AdBlocker()

class AdBlocker {
  // Store the last 500 URLs checked
  // Store 10 x 50 URLs in the array called timeOrderedCacheChunks. This is a FIFO array,
  // Throw out a 50 URL chunk when the array is full
  var fifoOfCachedUrlChunks: [NSMutableDictionary] = []
  let maxChunks = 10
  let maxUrlsPerChunk = 50

  private init() {
  }

  class var singleton: AdBlocker {
    return _singleton
  }

  func shouldBlock(request: NSURLRequest) -> Bool {
    // TODO: there shouldn't be a cost to checking unchanged prefs, please confirm this
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let profile = appDelegate.getProfile(UIApplication.sharedApplication())
    if !(profile.prefs.boolForKey(AdBlockSetting.prefKey) ?? AdBlockSetting.defaultValue) {
      return false
    }

    guard let url = request.URL,
      domain = request.mainDocumentURL?.host else {
        return false
    }

    if let host = url.host where host.contains(domain) {
      return false
    }

    // A cache entry is like: timeOrderedCacheChunks[0]["www.microsoft.com_http://some.url"] = true/false for blocking
    let key = "\(domain)_\(url.absoluteString)"

    // synchronize code from this point on.
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

    for urls in fifoOfCachedUrlChunks {
      if let urlIsBlocked = urls[key] {
        if urlIsBlocked as! Bool {
#if LOG_AD_BLOCK
          print("blocked (cached result) \(url.absoluteString)")
#endif
        }
        return urlIsBlocked as! Bool
      }
    }

    let isBlocked = AdBlockCppFilter.singleton().checkWithCppABPFilter(url.absoluteString, mainDocumentUrl: domain)

    if fifoOfCachedUrlChunks.count > maxChunks {
      fifoOfCachedUrlChunks.removeFirst()
    }

    if fifoOfCachedUrlChunks.last == nil || fifoOfCachedUrlChunks.last?.count > maxUrlsPerChunk {
      fifoOfCachedUrlChunks.append(NSMutableDictionary())
    }

    if let cacheChunkUrlAndDomain = fifoOfCachedUrlChunks.last {
      cacheChunkUrlAndDomain[key] = isBlocked
    }

#if LOG_AD_BLOCK
    if isBlocked {
      print("blocked \(url.absoluteString)")
    }
#endif

    return isBlocked
  }
}