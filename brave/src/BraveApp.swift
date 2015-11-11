import Foundation
import Fabric
import Crashlytics

// Any app-level hooks we need from Firefox, just add a call to here
class BraveApp {
  static let kNotificationAppLaunching = "kNotificationAppLaunching"

  class func willFinishLaunching() {
    Fabric.with([Crashlytics.self])
    NSURLProtocol.registerClass(URLProtocol);

    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationAppLaunching, object: nil)

    // add more global init code here if you like
  }
}