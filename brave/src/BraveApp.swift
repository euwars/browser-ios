import Foundation
import Fabric
import Crashlytics
import Shared

private let _singleton = BraveApp()

let kAppBootingIncompleteFlag = "kAppBootingIncompleteFlag"

// Any app-level hooks we need from Firefox, just add a call to here
class BraveApp {
  static var isSafeToRestoreTabs = true
  // If app runs for this long, clear the saved pref that indicates it is safe to restore tabs
  static let kDelayBeforeDecidingAppHasBootedOk = (Int64(NSEC_PER_SEC) * 10) // 10 sec

  class var singleton: BraveApp {
    return _singleton
  }

  class func setupCacheDefaults() {
    NSURLCache.sharedURLCache().memoryCapacity = 6 * 1024 * 1024; // 6 MB
    NSURLCache.sharedURLCache().diskCapacity = 40 * 1024 * 1024;
  }

  // Be aware: the Prefs object has not been created yet
  class func willFinishLaunching_begin() {
    Fabric.with([Crashlytics.self])
    BraveApp.setupCacheDefaults()
    NSURLProtocol.registerClass(URLProtocol);

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
  }

  // Prefs are created at this point
  class func willFinishLaunching_end() {
    if AppConstants.IsRunningTest {
      print("In test mode, bypass automatic vault registration.")
    } else {
      VaultManager.userProfileInit()
      VaultManager.sessionLaunch()
    }

    BraveApp.isSafeToRestoreTabs = BraveApp.getPref(kAppBootingIncompleteFlag) == nil
    BraveApp.setPref("remove me when booted", forKey: kAppBootingIncompleteFlag)
    BraveApp.getPrefs()?.synchronize()
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, BraveApp.kDelayBeforeDecidingAppHasBootedOk),
      dispatch_get_main_queue(), {
      BraveApp.removePref(kAppBootingIncompleteFlag)
    })
  }

  // This can only be checked ONCE, the flag is cleared after this.
  // This is because BrowserViewController asks this question after the startup phase, 
  // when tabs are being created by user actions. So without more refactoring of the
  // Firefox logic, this is the simplest solution.
  class func shouldRestoreTabs() -> Bool {
    let ok = BraveApp.isSafeToRestoreTabs
    BraveApp.isSafeToRestoreTabs = true
    return ok
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

  class func getPrefs() -> NSUserDefaults? {
    assert(NSUserDefaultsPrefs.prefixWithDotForBrave.characters.count > 0)
    return NSUserDefaults(suiteName: "group.com.brave.ios.browser")
  }

  class func getPref(pref: String) -> AnyObject? {
    return getPrefs()?.objectForKey(NSUserDefaultsPrefs.prefixWithDotForBrave + pref)
  }

  class func setPref(val: AnyObject, forKey: String) {
    getPrefs()?.setObject(val, forKey: NSUserDefaultsPrefs.prefixWithDotForBrave + forKey)
  }

  class func removePref(pref: String) {
    getPrefs()?.removeObjectForKey(NSUserDefaultsPrefs.prefixWithDotForBrave + pref)
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
