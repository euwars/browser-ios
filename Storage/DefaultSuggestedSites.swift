/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class DefaultSuggestedSites {
    public static let sites = [
      "default" : [
        SuggestedSiteData(
            url: "https://www.google.com",
            bgColor: "e6e6e6",
            imageUrl: "asset://suggestedsites_google",
            faviconUrl: "asset://braveLogo",
            trackingId: 632,
            title: NSLocalizedString("Search Google", comment: "Tile title for Google")
        ),
        SuggestedSiteData(
            url: "https://www.yahoo.com",
            bgColor: "420894",
            imageUrl: "asset://suggestedsites_yahoo",
            faviconUrl: "asset://braveLogo",
            trackingId: 632,
            title: NSLocalizedString("Search Yahoo", comment: "Tile title for Yahoo")
        ),
        SuggestedSiteData(
            url: "https://www.bing.com",
            bgColor: "808080",
            imageUrl: "asset://suggestedsites_bing",
            faviconUrl: "asset://braveLogo",
            trackingId: 632,
            title: NSLocalizedString("Search Bing", comment: "Tile title for Bing")
        ),
        SuggestedSiteData(
            url: "https://www.duckduckgo.com",
            bgColor: "ffffff",
            imageUrl: "asset://suggestedsites_DDG",
            faviconUrl: "asset://braveLogo",
            trackingId: 632,
            title: NSLocalizedString("Seach DuckDuckGo", comment: "Tile title for DDG")
        ),
        SuggestedSiteData(
            url: "https://www.wikipedia.com",
            bgColor: "e6e6e6",
            imageUrl: "asset://suggestedsites_wiki",
            faviconUrl: "asset://braveLogo",
            trackingId: 632,
            title: NSLocalizedString("Search Wikipedia", comment: "Tile title for wikipedia")
        ),
        SuggestedSiteData(
            url: "https://www.brave.com",
            bgColor: "0xf37c00",
            imageUrl: "asset://suggestedsites_bravesupport",
            faviconUrl: "asset://braveLogo",
            trackingId: 631,
            title: NSLocalizedString("Brave Help and Support", comment: "Tile title for App Help")
        )
      ]
     ]
}
