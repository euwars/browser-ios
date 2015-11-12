import Foundation

class VaultManager {
  static let braveUserIdKey = "BraveUserId"
  static var sessionId: String? = NSUUID().UUIDString as String

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

  class func userProfileInit() {
    if (getProfile().prefs.stringForKey(braveUserIdKey) != nil) {
      return
    }

    // Register users with the vault.
    let uuid = NSUUID().UUIDString
    getProfile().prefs.setString(uuid, forKey: braveUserIdKey)

    guard let requestURL = NSURL(string:"\(getVaultServerHost())/v1/users/\(uuid)") else {
      return
    }
    let request = NSMutableURLRequest(URL: requestURL)
    request.HTTPMethod = "PUT"

    let session = NSURLSession.sharedSession()
    let dataTask = session.dataTaskWithRequest(request) { (data, response, error) in
      if error != nil {
        print("vault error \(error)")
      } else {
        if let data = data,
          jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding) {
#if DEBUG
          print("Parsed JSON: '\(jsonStr)'")
#endif
        } else {
          print("unexpected vault error in user init")
        }
      }
    }
    dataTask.resume()
  }

  class func sessionLaunch() {
    sessionId = nil

    sessionIntent("{ \"sessionId\" : \"\(getSessionId())\"\n"             +
                  ", \"timestamp\" : \(round(NSDate().timeIntervalSince1970 * 1000))\n" +
                  ", \"type\"      : \"browser.app.launch\"\n"            +
                  ", \"payload\"   : {}\n"                                +
                  "}\n")
  }

 class func sessionTerminate() {
    if (sessionId == nil) {
      return
    }

    sessionIntent("{ \"sessionId\" : \"\(getSessionId())\"\n"             +
                  ", \"timestamp\" : \(round(NSDate().timeIntervalSince1970 * 1000))\n" +
                  ", \"type\"      : \"browser.app.terminate\"\n"         +
                  ", \"payload\"   : {}\n"                                +
                  "}\n")

    sessionId = nil
  }

  private class func sessionIntent(body: String) {
    guard let requestURL = NSURL(string:"\(getVaultServerHost())/v1/users/\(getBraveUserId())/intents") else {
      return
    }
    let request = NSMutableURLRequest(URL: requestURL)
    request.HTTPMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)

    let session = NSURLSession.sharedSession()
    let dataTask = session.dataTaskWithRequest(request) { (data, response, error) in
      if error != nil {
        print("vault error \(error)")
      } else {
        if let data = data,
          jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding) {
#if DEBUG
          print("Parsed JSON: '\(jsonStr)'")
#endif
        } else {
          print("unexpected vault error in user init")
        }
      }
    }
    dataTask.resume()
  }
}
