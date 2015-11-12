import Foundation
import Fabric
import Crashlytics

// Any app-level hooks we need from Firefox, just add a call to here
class BraveApp {
  static let kNotificationAppLaunching = "kNotificationAppLaunching"
  static let kNotificationAppBackgrounded = "kNotificationAppBackgrounded"
  static let braveUserIdKey = "BraveUserId"

  class func willFinishLaunching() {
    Fabric.with([Crashlytics.self])
    NSURLProtocol.registerClass(URLProtocol);

    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationAppLaunching, object: nil)

    // Register users with the vault.
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let profile = appDelegate.getProfile(UIApplication.sharedApplication())
    if profile.prefs.stringForKey(braveUserIdKey) == nil {
        let uuid = NSUUID().UUIDString
        profile.prefs.setString(uuid, forKey: braveUserIdKey)

        let profile = appDelegate.getProfile(UIApplication.sharedApplication())
        var vaultServerHost = profile.prefs.stringForKey(VaultAddressSetting.prefKey) ?? VaultAddressSetting.defaultValue
        if !vaultServerHost.startsWith("http") {
            vaultServerHost = "http://" + vaultServerHost
        }

        let requestURL: NSURL? = NSURL(string:"\(vaultServerHost)/v1/users/\(uuid)")
        let request = NSMutableURLRequest(URL: requestURL!)
        request.HTTPMethod = "PUT"

        let session = NSURLSession.sharedSession()
        let dataTask = session.dataTaskWithRequest(request) { (data, response, error) in
            if error != nil {
                print("vault error \(error)")
            } else {
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Parsed JSON: '\(jsonStr)'")
            }
        }
        dataTask.resume()
    }
  }

  class func didEnterBackground() {
    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationAppBackgrounded, object: nil)
  }

  class func shouldHandleOpenURL(components: NSURLComponents) -> Bool {
    // TODO look at what x-callback is for
    return components.scheme == "brave" || components.scheme == "brave-x-callback"
  }
}