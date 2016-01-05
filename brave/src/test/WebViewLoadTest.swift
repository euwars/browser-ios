
import Foundation
import XCTest
@testable import Client
import Shared

class WebViewLoadTest: XCTestCase {
  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func adblockOn(enable:Bool) {
    if enable {
      NSURLProtocol.registerClass(URLProtocol);
    } else {
      NSURLProtocol.unregisterClass(URLProtocol);
    }
  }

  func loadSite(site:String, webview:BraveWebView) ->Bool {
    let url = NSURL(string: "http://" + site)
    expectationForNotification(BraveWebView.kNotificationWebViewLoadCompleteOrFailed, object: nil, handler:nil)
    webview.loadRequest(NSURLRequest(URL: url!))
    var isOk = true
    waitForExpectationsWithTimeout(15) { (error:NSError?) -> Void in
      if let _ = error {
        isOk = false
      }
    }

    webview.stopLoading()
    expectationForNotification(BraveWebView.kNotificationWebViewLoadCompleteOrFailed, object: nil, handler:nil)
    webview.loadHTMLString("<html><head></head><body></body></html>", baseURL: nil)
    waitForExpectationsWithTimeout(2, handler: nil)

    return isOk
  }


  func loadSites(sites:[String]) {
    let w = BraveWebView(frame: CGRectMake(0,0,200,200))
    for site in sites {
        print("\(site)")
        self.loadSite(site, webview: w)
    }
  }

  /* The following uses XCodes built-in performance measurement XCTest.measureBlock which has no way of handling
  unexpectedly long loads. Ideally if the load takes >15s we would throw out the result. 
  I treat >15s as a load failure, but no test result is reported when that happens, and the test must 
  be repeated.
  XCTest.measureBlock runs each test 10x.
  */

  var groupA = ["businessinsider.com", "kotaku.com"]
  var groupB = ["imore.com", "nytimes.com"]

  func testAdBlockOn_A() {
    adblockOn(true)
    self.loadSites(self.groupA)
    measureBlock({
      self.loadSites(self.groupA)
    })
  }

  func testAdBlockOff_A() {
    adblockOn(false)
    self.loadSites(self.groupA)
    measureBlock({
      self.loadSites(self.groupA)
    })
  }

  func testAdBlockOn_B() {
    adblockOn(true)
    self.loadSites(self.groupB)
    measureBlock({
      self.loadSites(self.groupB)
    })
  }

  func testAdBlockOff_B() {
    adblockOn(false)
    self.loadSites(self.groupB)
    measureBlock({
      self.loadSites(self.groupB)
    })
  }

  // End of XCTest measureBlock

  // Uses my own test timing, results aren't as detailed as the XCTest.measureBlock
  func testTopSlowSites() {
    let sites = ["nytimes.com", "macworld.com", "wired.com", "theverge.com",
      "businessinsider.com", "imore.com", "kotaku.com", "huffingtonpost.com"]
    var dict = [String:[[Double]]]()

    let webview = BraveWebView(frame: CGRectMake(0,0,200,200))
    for _ in 0..<3 {
      for i in 0..<2 {
        adblockOn(i == 1)

        for site in sites {
          print("\(site)")

          // prime it
          loadSite(site, webview: webview)

          let timeStart = NSDate.timeIntervalSinceReferenceDate()
          let ok = loadSite(site, webview: webview)
          if !ok {
            continue
          }
          let time = NSDate.timeIntervalSinceReferenceDate() - timeStart

          if time < 1 {
            print("(\(i)) skipping \(site), load too fast \(time)")
            continue
          }

          if dict[site] == nil {
            dict[site] = [[Double](), [Double]()]
          }

          dict[site]![i].append(time)
        }
      }
    }

    var countSitesWithFasterLoad = 0
    var averages = [String:(Double, Double)]()
    for (key, noBlockAndBlockArrays) in dict {
      for i in 0..<2 {
        let arr = noBlockAndBlockArrays[i]
        let average = arr.reduce(0.0) { return ($0 + $1) } / Double(arr.count)
        print("\(i) \(key) \(average)")
        if i < 1 {
          averages[key] = (average, 0.0)
        } else {
          averages[key] = (averages[key]!.0, average)
          if (averages[key]!.1 < averages[key]!.0) {
            countSitesWithFasterLoad++
          }
        }
      }
    }

    XCTAssert(countSitesWithFasterLoad == sites.count, "Expected all sites to load faster with ad block")
  }


#if TEST_ALEXA500
  // If you have an hour+ to wait, this will run through a huge list of sites. 
  // It is very useful to stress the app, you can watch memory, or just see if there are any major errors
  // in the console.
  func testStressUsingAlexa500() {
    let w = BraveWebView(frame: CGRectMake(0,0,200,200))
    var count = 0
    for site in sites500 {
      print("Site: \(count++) \(site)")
      loadSite(site, webview: w)
    }
  }
#endif

  func testOpenUrlUsingBraveSchema() {
    expectationForNotification(BraveWebView.kNotificationWebViewLoadCompleteOrFailed, object: nil, handler:nil)
    let site = "google.ca"
    let ok = UIApplication.sharedApplication().openURL(
      NSURL(string: "brave://open-url?url=https%253A%252F%252F" + site)!)
    waitForExpectationsWithTimeout(10, handler: nil)
    XCTAssert(ok, "open url failed for site: \(site)")
  }
}
