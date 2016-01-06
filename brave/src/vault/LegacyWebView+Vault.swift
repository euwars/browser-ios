/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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

var loadedCache = [String: String]()
func loadJs(name: String) -> String {
  if let cached = loadedCache[name] {
    return cached
  }
  let path = NSBundle.mainBundle().pathForResource(name, ofType: "js")
  assert(path != nil)
  let result = try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
  loadedCache[name] = result
  return result
}

func loadAndRunJs(name: String, _ webView: UIWebView) {
  let fileContents = loadJs(name)
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

extension BraveWebView {
  func replaceImagesUsingTheVault(webView: UIWebView) {
    let isJsResourcesLoaded = webView.stringByEvaluatingJavaScriptFromString("typeof _brave_adInfo !== 'undefined'")
    
    if (isJsResourcesLoaded != "true") {
      loadAndRunJs("adInfo", webView)
      loadAndRunJs("adInfo-wrapper", webView)
    }
    
    guard var host = webView.request?.URL?.hostWithGenericSubdomainPrefixRemoved() else { return }
    // TODO: ffox code has a function surely to clean up URL
    host = host.regexReplacePattern(".+error\\.html\\?url=http", with: "http")
    let divSizeQuery = loadJs("adInfo-divquerytemplate").stringByReplacingOccurrencesOfString("HOST", withString: host)
    
    let jsonResult = webView.stringByEvaluatingJavaScriptFromString(divSizeQuery)
    if (jsonResult == nil || jsonResult?.characters.count < 1) {
      return
    }
    
    let divNamesAndSizes = jsonParseArray(jsonResult)
    if (divNamesAndSizes.count < 1) {
      return
    }
    
    // TODO: this should probably be converted to a setting somewhere
    let adHost = "//cdn.brave.com";
    
    for item in divNamesAndSizes {
      let divWidth = item["width"] as? Int ?? 0
      let divHeight = item["height"] as? Int ?? 0
      if (divWidth == 0 || divHeight == 0) {
        continue;
      }
      let divId = item["divId"] as! String
      let js = "_brave_replaceDivWithNewContent({'divId':'\(divId)'," +
      "'width':\(divWidth), 'height':\(divHeight),'replacementUrl':'\(adHost)'})"
      
      webView.stringByEvaluatingJavaScriptFromString(js)
    }
  }
}
