import Foundation

import Foundation
import XCTest
@testable import Client
import Shared

class VaultIntentTests: XCTestCase {
  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func setupExpectation() {
    expectationForNotification(VaultManager.kNotificationVaultSimpleResponse, object: nil,
      handler: { notification in
        guard let response = notification.userInfo?["response"] else { XCTFail("no response"); return false }
        // Please fill in: response.contains("some expected thing")
        let data = response.dataUsingEncoding(NSUTF8StringEncoding)
        if data == nil || data?.length < 1 {
          // maybe we should specify setupExpectation(isEmptyResponseOk: true/false)
          return true
        }

        do {
          guard let json = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
            as? [String:AnyObject] else { XCTFail("bad response"); return false }
          if json["statusCode"] != nil {
            XCTAssert(json["statusCode"] as? Int == 200, "Response: \(json)")
          }
        } catch let error as NSError {
            XCTFail("\(error)")
        }
        return true
    })
  }

  func waitForExpectation() {
    waitForExpectationsWithTimeout(10, handler: { error in
      XCTAssert(error == nil, "vault response error: \(error)")
    })
  }

  func testLiveUserProfileInit() {
    setupExpectation()
    VaultManager.userProfileInit()
    waitForExpectation()
  }
  
  func getProfile() -> Profile {
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let profile = appDelegate.getProfile(UIApplication.sharedApplication())
    return profile
  }

  // test expected response against live server
  func testLiveSessionIntent() {
    testLiveUserProfileInit() // required to do further calls?
    setupExpectation()
    VaultManager.sessionLaunch()
    waitForExpectation()
   }
}