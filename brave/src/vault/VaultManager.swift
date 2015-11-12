import Foundation

class VaultManager {
  static let braveUserIdKey = "BraveUserId"

  class func userProfileInit() {
    // Register users with the vault.
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let profile = appDelegate.getProfile(UIApplication.sharedApplication())
    if profile.prefs.stringForKey(braveUserIdKey) != nil {
      return
    }

    let uuid = NSUUID().UUIDString
    profile.prefs.setString(uuid, forKey: braveUserIdKey)

    var vaultServerHost = profile.prefs.stringForKey(VaultAddressSetting.prefKey) ?? VaultAddressSetting.defaultValue
    if !vaultServerHost.startsWith("http") {
      vaultServerHost = "http://" + vaultServerHost
    }

    guard let requestURL = NSURL(string:"\(vaultServerHost)/v1/users/\(uuid)") else {
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
          profile.prefs.setString(jsonStr as String, forKey: braveUserIdKey)
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