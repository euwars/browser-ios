import UIKit
import CoreData

var requestCount = 0
let markerRequestHandled = "request-already-handled"

class URLProtocol: NSURLProtocol {

  var connection: NSURLConnection!
  var mutableData: NSMutableData!
  var response: NSURLResponse!

  override class func canInitWithRequest(request: NSURLRequest) -> Bool {
    //print("Request #\(requestCount++): URL = \(request.URL?.absoluteString)")

    if let scheme = request.URL?.scheme where !scheme.startsWith("http") {
      return false
    }

    if NSURLProtocol.propertyForKey(markerRequestHandled, inRequest: request) != nil {
      return false
    }

    return AdBlocker.singleton.shouldBlock(request)
  }

  override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
    return request
  }

  override func startLoading() {
    let newRequest = self.request.mutableCopy() as! NSMutableURLRequest
    NSURLProtocol.setProperty(true, forKey: markerRequestHandled, inRequest: newRequest)
    self.connection = NSURLConnection(request: newRequest, delegate: self)


    // To block the load nicely, return an empty result to the client.
    // Nice => UIWebView's isLoading property gets set to false
    // Not nice => isLoading stays true while page waits for blocked items that never arrive

    // IIRC expectedContentLength of 0 is buggy (can't find the reference now).
    guard let url = request.URL else { return }
    let response = NSURLResponse(URL: url, MIMEType: "text/html", expectedContentLength: 1, textEncodingName: "utf-8")
    client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
    client?.URLProtocol(self, didLoadData: NSData())
    client?.URLProtocolDidFinishLoading(self)
  }

  override func stopLoading() {
    if self.connection != nil {
      self.connection.cancel()
    }
    self.connection = nil
  }

// MARK: NSURLConnection

  func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
    self.client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)

    self.response = response
    self.mutableData = NSMutableData()
  }

  func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
    self.client!.URLProtocol(self, didLoadData: data)
    self.mutableData.appendData(data)
  }

  func connectionDidFinishLoading(connection: NSURLConnection!) {
    self.client!.URLProtocolDidFinishLoading(self)
  }

  func connection(connection: NSURLConnection!, didFailWithError error: NSError!) {
    self.client!.URLProtocol(self, didFailWithError: error)
  }
}