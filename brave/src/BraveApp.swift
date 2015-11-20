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
    NSNotificationCenter.defaultCenter().addObserver(BraveApp.singleton,
      selector: "prefsChanged_verifySuiteNameIsOk:", name: NSUserDefaultsDidChangeNotification, object: nil)

    if BraveUX.DebugShowBorders {
      UIView.bordersOn()
    }

    // desktop UA for testing
    //      let defaults = NSUserDefaults(suiteName: AppInfo.sharedContainerIdentifier())!
    //      let desktop = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; it-it) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16"
    //      defaults.registerDefaults(["UserAgent": desktop])

#endif

    // skip first run until we have our own
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let profile = appDelegate.getProfile(UIApplication.sharedApplication())
    profile.prefs.setInt(1, forKey: IntroViewControllerSeenProfileKey)
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

  class func getPref(pref: String) -> AnyObject? {
    guard let defaults = NSUserDefaults(suiteName: "group.com.brave.ios.browser") else { return nil }
    return defaults.objectForKey(NSUserDefaultsPrefs.prefixWithDotForBrave + pref)
  }

  class func setPref(val: AnyObject, forKey: String) {
    guard let defaults = NSUserDefaults(suiteName: "group.com.brave.ios.browser") else { return }
    return defaults.setObject(val, forKey: NSUserDefaultsPrefs.prefixWithDotForBrave + forKey)
  }

  #if DEBUG
  // do a debug only verification that using the correct name for getting the defaults
  @objc func prefsChanged_verifySuiteNameIsOk(info: NSNotification) {
    NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: nil)
    let defaults = info.object as! NSUserDefaults
    let defaults2 = NSUserDefaults(suiteName: "group.com.brave.ios.browser")
    assert(defaults.dictionaryRepresentation().elementsEqual(defaults2!.dictionaryRepresentation(), isEquivalent: { (a:(String, AnyObject), b:(String, AnyObject)) -> Bool in
      return a.1 as? String == b.1 as? String
    }))
  }
  #endif

}
