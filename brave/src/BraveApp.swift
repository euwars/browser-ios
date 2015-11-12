import Foundation
import Fabric
import Crashlytics

// Any app-level hooks we need from Firefox, just add a call to here
class BraveApp {
  static let kNotificationAppLaunching = "kNotificationAppLaunching"
  static let kNotificationAppBackgrounded = "kNotificationAppBackgrounded"

  class func willFinishLaunching() {
    Fabric.with([Crashlytics.self])
    NSURLProtocol.registerClass(URLProtocol);

    VaultManager.userProfileInit()

    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationAppLaunching, object: nil)
  }

  class func didEnterBackground() {
    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationAppBackgrounded, object: nil)
  }

  class func shouldHandleOpenURL(components: NSURLComponents) -> Bool {
    // TODO look at what x-callback is for
    return components.scheme == "brave" || components.scheme == "brave-x-callback"
  }

}