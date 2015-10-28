var domainInfo = _brave_adInfo['HOST'];

domainInfo && JSON.stringify(domainInfo.map(function(x) {
  var node = document.querySelector('[id=' + x.replaceId + ']:not([data-ad-replaced])');
  node.setAttribute('data-ad-replaced', 1);
  if (!node) { 
    return {};
  }
  return {
    'divId': x.replaceId,
    'width': node.offsetWidth,
    'height': node.offsetHeight
  };
}))