/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class DefaultSuggestedSites {
    public static let sites = [
        SuggestedSiteData(
            url: "https://www.brave.com",
            bgColor: "0xf37c00",
            imageUrl: "asset://suggestedsites_brave",
            faviconUrl: "asset://braveLogo",
            trackingId: 632,
            title: NSLocalizedString("Brave Software", comment: "Tile title for Brave")
        ),
        SuggestedSiteData(
            url: "https://www.brave.com",
            bgColor: "0xf37c00",
            imageUrl: "asset://suggestedsites_fxsupport",
            faviconUrl: "asset://mozLogo",
            trackingId: 631,
            title: NSLocalizedString("Brave Help and Support", comment: "Tile title for App Help")
        )
    ]
}


