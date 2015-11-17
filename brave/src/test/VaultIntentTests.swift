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
        do {
          guard let json = try NSJSONSerialization.JSONObjectWithData(response.dataUsingEncoding(NSUTF8StringEncoding)!, options: [])
            as? [String:AnyObject] else { XCTFail("bad response"); return false }
          XCTAssert(json["statusCode"] as? Int == 200, "Response: \(json)")
        } catch _ {

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
  

  // test expected response against live server
  func testLiveSessionIntent() {
    testLiveUserProfileInit() // required to do further calls?
    setupExpectation()
    VaultManager.sessionLaunch()
    waitForExpectation()
   }
}