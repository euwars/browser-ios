import Foundation

class VaultManager {
  static let braveUserIdKey = "BraveUserId"
  static let sessionId: String = NSUUID().UUIDString as String

  class func getBraveUserId() -> String? {
    return getProfile().prefs.stringForKey(braveUserIdKey)
  }

  class func getSessionId() -> String {
    return sessionId
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
    if (getBraveUserId() == nil) {
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
}