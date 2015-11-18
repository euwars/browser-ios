import Foundation
import Fabric
import Crashlytics
import Shared

private let _singleton = BraveApp()

// Any app-level hooks we need from Firefox, just add a call to here
class BraveApp {
  class var singleton: BraveApp {
    return _singleton
  }

  class func setupCacheDefaults() {
    NSURLCache.sharedURLCache().memoryCapacity = 6 * 1024 * 1024; // 6 MB
    NSURLCache.sharedURLCache().diskCapacity = 40 * 1024 * 1024;
  }

  class func willFinishLaunching() {
    Fabric.with([Crashlytics.self])
    BraveApp.setupCacheDefaults()
    NSURLProtocol.registerClass(URLProtocol);

    if AppConstants.IsRunningTest {
      print("In test mode, bypass automatic vault registration.")
    } else {
      VaultManager.userProfileInit()
      VaultManager.sessionLaunch()
    }

    NSNotificationCenter.defaultCenter().addObserver(BraveApp.singleton,
      selector: "didEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)

    NSNotificationCenter.defaultCenter().addObserver(BraveApp.singleton,
      selector: "willEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: nil)

    NSNotificationCenter.defaultCenter().addObserver(BraveApp.singleton,
      selector: "memoryWarning:", name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)

    //  these quiet the logging from the core of fx ios
    GCDWebServer.setLogLevel(5)
    Logger.syncLogger.setup(.None)
    Logger.browserLogger.setup(.None)

#if DEBUG
    if BraveUX.DebugShowBorders {
      UIView.bordersOn()
    }

    // desktop UA for testing
    //      let defaults = NSUserDefaults(suiteName: AppInfo.sharedContainerIdentifier())!
    //      let desktop = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; it-it) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16"
    //      defaults.registerDefaults(["UserAgent": desktop])

#endif
  }

  @objc func memoryWarning(_: NSNotification) {
    NSURLCache.sharedURLCache().memoryCapacity = 0
    BraveApp.setupCacheDefaults()
  }

  @objc func didEnterBackground(_: NSNotification) {
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
