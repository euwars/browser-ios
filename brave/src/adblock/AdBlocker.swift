/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

private let _singleton = AdBlocker()

// Store the last 500 URLs checked
// Store 10 x 50 URLs in the array called timeOrderedCacheChunks. This is a FIFO array,
// Throw out a 50 URL chunk when the array is full
class UrlFifo {
    var fifoOfCachedUrlChunks: [NSMutableDictionary] = []
    let maxChunks = 10
    let maxUrlsPerChunk = 50

    // the url key is a combination of urls, the main doc url, and the url being checked
    func addIsBlockedForUrlKey(urlKey: String, isBlocked: Bool) {
        if fifoOfCachedUrlChunks.count > maxChunks {
            fifoOfCachedUrlChunks.removeFirst()
        }

        if fifoOfCachedUrlChunks.last == nil || fifoOfCachedUrlChunks.last?.count > maxUrlsPerChunk {
            fifoOfCachedUrlChunks.append(NSMutableDictionary())
        }

        if let cacheChunkUrlAndDomain = fifoOfCachedUrlChunks.last {
            cacheChunkUrlAndDomain[urlKey] = isBlocked
        }
    }

    func containsAndIsBlocked(needle: String) -> Bool? {
        for urls in fifoOfCachedUrlChunks {
            if let urlIsBlocked = urls[needle] {
                if urlIsBlocked as! Bool {
                    #if LOG_AD_BLOCK
                        print("blocked (cached result) \(url.absoluteString)")
                    #endif
                }
                return urlIsBlocked as? Bool
            }
        }
        return nil
    }
}

class AdBlocker {
    static let prefKeyAdBlockOn = "braveBlockAds"
    static let prefKeyAdBlockOnDefaultValue = true
    static let dataVersion = "1"

    lazy var networkFileLoader: NetworkDataFileLoader = {
        let dataUrl = NSURL(string: "https://s3.amazonaws.com/adblock-data/\(dataVersion)/ABPFilterParserData.dat")!
        let dataFile = "abp-data-\(dataVersion).dat"
        let loader = NetworkDataFileLoader(url: dataUrl, file: dataFile, localDirName: "abp-data")
        loader.delegate = self
        return loader
    }()

    var fifoOfCachedUrlChunks = UrlFifo()
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

    // We can add whitelisting logic here for puzzling adblock problems
    private func cleanUrlWithArgs(url: String, forMainDocDomain domain: String) -> String? {
        // https://github.com/brave/browser-ios/issues/89
        if !domain.contains("yahoo") || !url.contains("s.yimg.com/zz/combo") {
            return nil
        }
        guard let pos = url.rangeOfString("?") else { return url }
        let basePart = url.substringToIndex(pos.startIndex)
        let urlargs = url.substringFromIndex(pos.startIndex.advancedBy(1))
        let sanitized = urlargs.characters.split("&").filter {
            item in
            let s = String(item)
            let isBad = s.contains("-ads-")
            if isBad { print("\(s)") }
            return !isBad
        }
        return "\(basePart)?\(String(sanitized.joinWithSeparator("&".characters)))"
    }


    func sanitizeURL(request: NSURLRequest) -> NSURLRequest? {
        if !isEnabled {
            return nil
        }

        guard var url = request.URL?.absoluteString,
            var domain = request.mainDocumentURL?.host else {
                return nil
        }

        url = stripLocalhostWebServer(url)
        domain = stripLocalhostWebServer(domain)
        if let host = request.URL?.host where host.contains(domain) {
            return nil
        }

        if !url.contains("&") {
            return nil
        }

        if let url = cleanUrlWithArgs(url, forMainDocDomain: domain) {
            let newRequest = URLProtocol.safeURLRequestClone(request)
            newRequest.URL = NSURL(string: url)
            return newRequest
        }
        return nil
    }

    func shouldBlock(request: NSURLRequest) -> Bool {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if !isEnabled {
            return false
        }

        guard var url = request.URL?.absoluteString,
            var domain = request.mainDocumentURL?.host else {
                return false
        }

        url = stripLocalhostWebServer(url)
        domain = stripLocalhostWebServer(domain)

        if let host = request.URL?.host where host.contains(domain) {
            return false
        }

        // A cache entry is like: fifoOfCachedUrlChunks[0]["www.microsoft.com_http://some.url"] = true/false for blocking
        let key = "\(domain)_" + url

        if let urlIsBlocked = fifoOfCachedUrlChunks.containsAndIsBlocked(key) {
            return urlIsBlocked
        }

        let isBlocked = AdBlockCppFilter.singleton().checkWithCppABPFilter(url,
            mainDocumentUrl: domain,
            acceptHTTPHeader:request.valueForHTTPHeaderField("Accept"))

        fifoOfCachedUrlChunks.addIsBlockedForUrlKey(key, isBlocked: isBlocked)

        #if LOG_AD_BLOCK
            if isBlocked {
                print("blocked \(url.absoluteString)")
            }
        #endif
        
        return isBlocked
    }
}

extension AdBlocker: NetworkDataFileLoaderDelegate {
    func setDataFile(data: NSData?) {
        AdBlockCppFilter.singleton().setAdblockDataFile(data)
    }

    func hasDataFile() -> Bool {
        return AdBlockCppFilter.singleton().hasAdblockDataFile()
    }
}
