import Foundation
import Shared
private let _singleton = AdBlocker()

class AdBlocker {
    static let prefKeyAdBlockOn = "braveBlockAds"
    static let prefKeyAdBlockOnDefaultValue = true

    // Store the last 500 URLs checked
    // Store 10 x 50 URLs in the array called timeOrderedCacheChunks. This is a FIFO array,
    // Throw out a 50 URL chunk when the array is full
    var fifoOfCachedUrlChunks: [NSMutableDictionary] = []
    let maxChunks = 10
    let maxUrlsPerChunk = 50
    var isEnabled = true

    private init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "prefsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
        updateEnabledState()
    }

    class var singleton: AdBlocker {
        return _singleton
    }

    func updateEnabledState() {
        let obj = BraveApp.getPref(AdBlocker.prefKeyAdBlockOn)
        isEnabled = obj as? Bool ?? AdBlocker.prefKeyAdBlockOnDefaultValue
    }

    @objc func prefsChanged(info: NSNotification) {
        updateEnabledState()
    }

    func shouldBlock(request: NSURLRequest) -> Bool {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if !isEnabled {
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

        let isBlocked = AdBlockCppFilter.singleton().checkWithCppABPFilter(url.absoluteString,
            mainDocumentUrl: domain,
            acceptHTTPHeader:request.valueForHTTPHeaderField("Accept"))

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