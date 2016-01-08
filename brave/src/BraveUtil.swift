/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}



extension String {
    func regexReplacePattern(pattern:String,  with:String) -> String {
        let regex = try! NSRegularExpression(pattern:pattern, options: [])
        return regex.stringByReplacingMatchesInString(self, options: [], range: NSMakeRange(0, self.characters.count), withTemplate: with)
    }
}

extension NSURL {
    func hostWithGenericSubdomainPrefixRemoved() -> String? {
        return host != nil ? stripGenericSubdomainPrefixFromUrl(host!) : nil
    }
}

// Firefox has uses urls of the form  http://localhost:6571/errors/error.html?url=http%3A//news.google.ca/ to populate the browser history, and load+redirect using GCDWebServer
func stripLocalhostWebServer(url: String) -> String {
    return url.regexReplacePattern(".+error\\.html\\?url=http", with: "http")
}

func stripGenericSubdomainPrefixFromUrl(url: String) -> String {
    return url.regexReplacePattern("^(m\\.|www\\.|mobile\\.)", with:"");
}
