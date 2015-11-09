#import <Foundation/Foundation.h>

@interface AdBlockCppFilter : NSObject

+ (instancetype)singleton;
- (BOOL)checkWithCppABPFilter:(NSString *)url mainDocumentUrl:(NSString *)mainDoc acceptHTTPHeader:(NSString *)acceptHeader;
@end
