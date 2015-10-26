#import "RNCachingURLProtocol.h"

@interface RNCachingURLProtocol (ShouldHandle)
+ (BOOL)shouldHandleRequest:(NSURLRequest*)request;
@end
