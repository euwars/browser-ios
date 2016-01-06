/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Based on idea from: http://www.icab.de/blog/2010/07/11/customize-the-contextual-menu-of-uiwebview/

(function(x, y) {
  function parseUrl(url) {
    if (url.startsWith("http")) {
      return url;
    } else if (url.startsWith("//")) {
      return window.location.protocol + url;
    } else {
      return window.location.protocol + '//' + window.location.hostname + url;
    }
  }

  var e = document.elementFromPoint(x, y);
  var result = {}
  while (e) {
    if (!e.tagName) {
      e = e.parentNode;
      continue;
    }

    if (e.tagName === 'A') {
      result['link'] = parseUrl(e.getAttribute('href'));
    } else if (e.tagName === 'IMG') {
      result['imagesrc'] = parseUrl(e.getAttribute('src'));
    }

    e = e.parentNode;
  }

  return JSON.stringify(result);
})


