/* eslint no-unused-vars: [2, {"varsIgnorePattern": "replaceDivWithNewContent"}] */

function _brave_replaceDivWithNewContent(replacerObject) {
  var divId = replacerObject.divId;
  var frameSrc = replacerObject.newContent;
  var width = replacerObject.width;
  var height = replacerObject.height;

  var selector = '[id="' + divId + '"]';
  var node = document.querySelector(selector);
  if (node) {
    console.log('------tag name: ' + node.tagName);
    if (node.tagName === 'IFRAME') {
      node.srcdoc = frameSrc;
    } else {
      //node.innerHTML = '<iframe src="' + srcUrl + '">';

      while (node.firstChild) {
        node.removeChild(node.firstChild);
      }
      var iframe = document.createElement('iframe');
      iframe.style.padding = 0;
      iframe.style.border = 0;
      iframe.style.margin = 0;
      iframe.style.width = width + 'px';
      iframe.style.height = height + 'px';
      iframe.srcdoc = frameSrc;
      node.appendChild(iframe);
    }
  } else {
    console.log('-------selector null: ' + selector);
  }
}
