#import "RNCachingURLProtocol+ShouldHandle.h"
#import "NSURL+Matcher.h"
#import "Adblock.h"

@implementation RNCachingURLProtocol (ShouldHandle)

+(BOOL)shouldHandleRequest:(NSURLRequest*)request
{
  // only handle http requests we haven't marked with our header.
  if ([[self supportedSchemes] containsObject:request.URL.scheme] &&
      ([request valueForHTTPHeaderField:RNCachingURLHeader] == nil))
  {
    Adblock* ad = [Adblock singleton];
    return [ad shouldBlock:request];
  }

  return NO;
}

- (void)startLoading
{
  // To block the load nicely, return an empty result to the client.
  // Nice => UIWebView's isLoading property gets set to false
  // Not nice => isLoading stays true while page waits for blocked items that never arrive

  // IIRC expectedContentLength of 0 is buggy (can't find the reference now).
  NSURLResponse* response = [[NSURLResponse alloc] initWithURL:self.request.URL MIMEType:@"text/html"
                                         expectedContentLength:1 textEncodingName:@"utf-8"];
  [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
  [[self client] URLProtocol:self didLoadData:[NSData data]];
  [[self client] URLProtocolDidFinishLoading:self];
}
@end
