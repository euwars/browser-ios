import Foundation
import Shared

class VaultManager {
  static let prefKeyServerAddress = "braveVaultServerAddress"
  static let prefKeyServerAddressDefaultValue = "https://vault-staging.brave.com"

  static let notificationVaultSimpleResponse = "notificationVaultSimpleResponse"

  static let braveUserIdKey = "BraveUserId"
  static var sessionId: String? = NSUUID().UUIDString as String

  static let vaultVersion = "v1"
  static let endpointUsers = "\(vaultVersion)/users"

  static let testFakeId = "FEEDFACE-FEED-FEED-FEED-FEEDFACEFEED"

  class func isHttpStatusSuccess(status: Int) -> Bool {
    return status / 100 == 2
  }

  class func getBraveUserId() -> String {
    if AppConstants.IsRunningTest  {
      return testFakeId
    }
    if (BraveApp.getPref(braveUserIdKey) == nil) {
      userProfileInit()
    }

    return BraveApp.getPref(braveUserIdKey) as? String ?? "ERROR-ID"
  }

  class func getSessionId() -> String {
    if let sessionId = sessionId { return sessionId }
    sessionId = NSUUID().UUIDString as String
    return sessionId!
  }

  class func getVaultServerHost() -> String {
    var vaultServerHost = BraveApp.getPref(VaultManager.prefKeyServerAddress) as? String ?? VaultManager.prefKeyServerAddressDefaultValue
#if DEBUG
    // Too lazy to type http when setting this in debug
    if !vaultServerHost.startsWith("http") {
      vaultServerHost = "http://" + vaultServerHost
    }
#endif
    return vaultServerHost
  }

  class func simpleRequest(urlString: String, httpMethod: String, contentType: String = "", bodyData: NSData = NSData()) {
    guard let requestURL = NSURL(string: urlString) else {
      return
    }

    #if DEBUG
    print("Vault request:\(urlString)")
    #endif

    let request = NSMutableURLRequest(URL: requestURL)
    request.HTTPMethod = httpMethod

    if contentType.characters.count > 1 {
      request.addValue(contentType, forHTTPHeaderField: "Content-Type")
    }

    if bodyData.length > 0 {
      request.HTTPBody = bodyData
    }

    let session = NSURLSession.sharedSession()
    let dataTask = session.dataTaskWithRequest(request) { (data, response, error) in
      if error != nil {
        print("vault error \(error)")
      } else {
        if let data = data,
          jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding) {
            #if DEBUG
              print("Parsed JSON: '\(jsonStr)'")
              NSNotificationCenter.defaultCenter().postNotificationName(notificationVaultSimpleResponse,
                object: nil, userInfo: ["response": jsonStr])
            #endif
        } else {
          print("unexpected vault error in user init")
        }
      }
    }
    dataTask.resume()
  }

  class func userProfileInit() {
    if (BraveApp.getPref(braveUserIdKey) != nil) {
      return
    }

    // Register users with the vault.
    let uuid = AppConstants.IsRunningTest ? testFakeId : NSUUID().UUIDString
    BraveApp.setPref(uuid, forKey: braveUserIdKey)

    let request = "\(getVaultServerHost())/\(endpointUsers)/\(uuid)"
    simpleRequest(request, httpMethod: "PUT")
  }

  class func sessionLaunch() {
    sessionId = nil
    sessionIntent("browser.app.launch")
  }

  class func sessionTerminate() {
    if (sessionId == nil) {
      return
    }

    sessionIntent("browser.app.terminate")
    sessionId = nil
  }

  private class func sessionIntent(type: String) {
    let body =
      "{ \"sessionId\" : \"\(getSessionId())\"\n" +
      ", \"timestamp\" : \(round(NSDate().timeIntervalSince1970 * 1000))\n" +
      ", \"type\"      : \"\(type)\"\n" +
      ", \"payload\"   : {}\n" +
    "}\n"
    guard let bodyData = body.dataUsingEncoding(NSUTF8StringEncoding) else { return }
    let request = "\(getVaultServerHost())/\(endpointUsers)/\(getBraveUserId())/intents"
    simpleRequest(request, httpMethod: "POST",
      contentType: "application/json",
      bodyData: bodyData)
  }
}
