#import <Foundation/Foundation.h>

#define kAdblockJsDir @"injected-js-adblock"
#define kWebViewJsDir @"injected-js-webview"

@interface ResourceLoader : NSObject
// Use defined dirs (above) for the 'dir' arg
+ (NSString*)stringForFile:(NSString*)name ofType:(NSString*)type inDir:(NSString*)dir;
@end
