import Foundation

extension String {
  func regexReplacePattern(pattern:String,  with:String) -> String {
    let regex = try! NSRegularExpression(pattern:pattern, options: [])
    return regex.stringByReplacingMatchesInString(self, options: [], range: NSMakeRange(0, self.characters.count), withTemplate: with)
  }
}

extension NSURL {
  func hostWithGenericSubdomainPrefixRemoved() -> String? {
    return host?.regexReplacePattern("^(m\\.|www\\.|mobile\\.)", with:"");
  }
}

func loadJs(name: String, _ webView: UIWebView) {
  let path = NSBundle.mainBundle().pathForResource(name, ofType: "js")
  assert(path != nil)
  let fileContents = try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
  webView.stringByEvaluatingJavaScriptFromString(fileContents)
}

func jsonParseArray(messageJSON: String?) -> [NSDictionary] {
  guard let data = messageJSON?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) else { return [] }

  do {
    let obj = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
    let result = obj as? [NSDictionary]
    return result ?? []
  } catch let error as NSError {
    print("Failed to load: \(error.localizedDescription)")
  }
  return []
}


extension LegacyWebView {
  func replaceImagesUsingTheVault(webView: UIWebView) {
    let isJsResourcesLoaded = webView.stringByEvaluatingJavaScriptFromString("typeof _brave_adInfo !== 'undefined'")

    if (isJsResourcesLoaded != "true") {
      loadJs("adInfo", webView)
      loadJs("adInfo-wrapper", webView)
    }

    guard let host = webView.request?.URL?.hostWithGenericSubdomainPrefixRemoved() else { return }
    let divSizeQuery = "var domainInfo = _brave_adInfo['\(host)'] && domainInfo &&" +
      "JSON.stringify(domainInfo.map(function(x) {" +
        "var node = document.querySelector('[id=' + x.replaceId + ']:not([data-ad-replaced])');" +
        // mark the divs that have been replaced, this can get called many times on a page
        "node.setAttribute('data-ad-replaced', 1);" +
        "if (!node) return {};" +
        "return { 'divId':x.replaceId, 'width':node.offsetWidth, 'height':node.offsetHeight };" +
      "}))"
    let jsonResult = webView.stringByEvaluatingJavaScriptFromString(divSizeQuery)
    if (jsonResult == nil || jsonResult?.characters.count < 1) {
      return
    }
    
    let divNamesAndSizes = jsonParseArray(jsonResult)
    if (divNamesAndSizes.count < 1) {
      return
    }

    for item in divNamesAndSizes {
      print("\(item)")
    }
  }
}