/* global abpFilterParser */
/* eslint no-unused-vars: [2, {"varsIgnorePattern": "loadList|shouldBlock"}] */

var parsedFilterData = {};

function loadList(easylist) {
  abpFilterParser.parse(easylist, parsedFilterData);
  return Object.keys(parsedFilterData).length;
}

var cachedInputData = {};

function shouldBlock(urlToCheck, currentPageDomain) {
  return abpFilterParser.matches(parsedFilterData,
    urlToCheck, {
      domain: currentPageDomain,
      elementTypeMaskMap: 0xFF,
    },
    cachedInputData);
}
