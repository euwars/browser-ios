#import <Foundation/Foundation.h>

#define kNotification_adBlocked @"kNotification_adBlocked"

@interface AdBlock : NSObject

+ (instancetype)singleton;
- (BOOL)shouldBlock:(NSURLRequest*)request;
- (NSString*)getBlockedAsJSArray;
- (BOOL)isAlreadyBlockedUrl:(NSURL*)url;
@end
