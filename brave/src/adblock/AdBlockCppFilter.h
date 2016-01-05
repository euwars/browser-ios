#import <Foundation/Foundation.h>

@interface AdBlockCppFilter : NSObject

+ (instancetype)singleton;
- (void)setAdblockDataFile:(NSData *)data;
- (BOOL)hasAdblockDataFile;
- (BOOL)checkWithCppABPFilter:(NSString *)url mainDocumentUrl:(NSString *)mainDoc acceptHTTPHeader:(NSString *)acceptHeader;
@end
