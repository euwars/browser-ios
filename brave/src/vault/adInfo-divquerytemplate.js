/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var domainInfo = _brave_adInfo['HOST'];

domainInfo && JSON.stringify(domainInfo.map(function(x) {
  var node = document.querySelector('[id=' + x.replaceId + ']:not([data-ad-node-visited])');
  node.setAttribute('data-ad-node-visited', 1);
  if (!node) { 
    return {};
  }
  return {
    'divId': x.replaceId,
    'width': x.width,
    'height': x.height
  };
}))