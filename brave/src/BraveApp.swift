import Foundation
import Fabric
import Crashlytics

private let _singleton = BraveApp()

// Any app-level hooks we need from Firefox, just add a call to here
class BraveApp {
  class var singleton: BraveApp {
    return _singleton
  }

  class func willFinishLaunching() {
    Fabric.with([Crashlytics.self])
    NSURLProtocol.registerClass(URLProtocol);
    VaultManager.userProfileInit()
    VaultManager.sessionLaunch()

    NSNotificationCenter.defaultCenter().addObserver(BraveApp.singleton,
      selector: "didEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)

    NSNotificationCenter.defaultCenter().addObserver(BraveApp.singleton,
      selector: "willEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
  }

  @objc func didEnterBackground(_ : NSNotification) {
    VaultManager.sessionTerminate()
  }

  @objc func willEnterForeground(_ : NSNotification) {
    VaultManager.sessionLaunch()
  }

  class func shouldHandleOpenURL(components: NSURLComponents) -> Bool {
    // TODO look at what x-callback is for
    return components.scheme == "brave" || components.scheme == "brave-x-callback"
  }
}
