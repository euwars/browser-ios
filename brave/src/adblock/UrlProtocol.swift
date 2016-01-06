/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
        // Reportedly not safe to use built-in cloning methods: http://openradar.appspot.com/11596316
        let newRequest = NSMutableURLRequest(URL: request.URL!, cachePolicy: request.cachePolicy, timeoutInterval: request.timeoutInterval)
        newRequest.allHTTPHeaderFields = request.allHTTPHeaderFields
        if let m = request.HTTPMethod {
            newRequest.HTTPMethod = m
        }
        if let b = request.HTTPBodyStream {
            newRequest.HTTPBodyStream = b
        }
        if let b = request.HTTPBody {
            newRequest.HTTPBody = b
        }

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