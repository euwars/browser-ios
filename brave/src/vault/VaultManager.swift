import Foundation

class VaultManager {
  static let kNotificationVaultSimpleResponse = "kNotificationVaultSimpleResponse"

  static let braveUserIdKey = "BraveUserId"
  static var sessionId: String? = NSUUID().UUIDString as String

  static let vaultVersion = "v1"
  static let endpointUsers = "\(vaultVersion)/users"


  class func getBraveUserId() -> String {
    return getProfile().prefs.stringForKey(braveUserIdKey) ?? "ERROR-ID"
  }

  class func getSessionId() -> String {
    if let sessionId = sessionId { return sessionId }
    sessionId = NSUUID().UUIDString as String
    return sessionId!
  }

  private class func getProfile() -> Profile {
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let profile = appDelegate.getProfile(UIApplication.sharedApplication())
    return profile
  }

  class func getVaultServerHost() -> String {
    var vaultServerHost = getProfile().prefs.stringForKey(VaultAddressSetting.prefKey) ?? VaultAddressSetting.defaultValue
#if DEBUG
    // Too lazy to type http when setting this in debug
    if !vaultServerHost.startsWith("http") {
      vaultServerHost = "http://" + vaultServerHost
    }
#endif
    return vaultServerHost
  }

  class func simpleRequest(urlString: String, httpMethod: String, contentType: String = "", bodyData: NSData = NSData()) {
    guard let requestURL = NSURL(string: urlString) else {
      return
    }
    let request = NSMutableURLRequest(URL: requestURL)
    request.HTTPMethod = httpMethod

    if contentType.characters.count > 1 {
      request.addValue(contentType, forHTTPHeaderField: "Content-Type")
    }

    if bodyData.length > 0 {
      request.HTTPBody = bodyData
    }

    let session = NSURLSession.sharedSession()
    let dataTask = session.dataTaskWithRequest(request) { (data, response, error) in
      if error != nil {
        print("vault error \(error)")
      } else {
        if let data = data,
          jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding) {
            #if DEBUG
              print("Parsed JSON: '\(jsonStr) \n request:\(urlString)'")
              NSNotificationCenter.defaultCenter().postNotificationName(kNotificationVaultSimpleResponse,
                object: nil, userInfo: ["response": jsonStr])
            #endif
        } else {
          print("unexpected vault error in user init")
        }
      }
    }
    dataTask.resume()
  }

  class func userProfileInit() {
    if (getProfile().prefs.stringForKey(braveUserIdKey) != nil) {
      return
    }

    // Register users with the vault.
    let uuid = NSUUID().UUIDString
    getProfile().prefs.setString(uuid, forKey: braveUserIdKey)

    let request = "\(getVaultServerHost())/\(endpointUsers)/\(uuid)"
    simpleRequest(request, httpMethod: "PUT")
  }

  class func sessionLaunch() {
    sessionId = nil
    sessionIntent("browser.app.launch")
  }

  class func sessionTerminate() {
    if (sessionId == nil) {
      return
    }

    sessionIntent("browser.app.terminate")
    sessionId = nil
  }

  private class func sessionIntent(type: String) {
    let body =
      "{ \"sessionId\" : \"\(getSessionId())\"\n" +
      ", \"timestamp\" : \(round(NSDate().timeIntervalSince1970 * 1000))\n" +
      ", \"type\"      : \"\(type)\"\n" +
      ", \"payload\"   : {}\n" +
    "}\n"
    guard let bodyData = body.dataUsingEncoding(NSUTF8StringEncoding) else { return }
    let request = "\(getVaultServerHost())/\(endpointUsers)/\(getBraveUserId())/intents"
    simpleRequest(request, httpMethod: "POST",
      contentType: "application/json",
      bodyData: bodyData)
  }
}
