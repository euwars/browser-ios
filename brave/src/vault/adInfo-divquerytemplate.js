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