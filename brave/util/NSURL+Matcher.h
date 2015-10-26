#import <UIKit/UIKit.h>

@interface NSURL (NSURL_Matcher)

- (BOOL)hasString:(NSString*)find;
- (BOOL)hasSuffix:(NSString *)find;
- (NSString*)hostWithLastTwoComponentsOnly;
- (NSString*)hostWithGenericSubdomainPrefixRemoved;
@end
