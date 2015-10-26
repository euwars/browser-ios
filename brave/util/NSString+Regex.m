#import "NSString+Regex.h"

@implementation NSString(Regex)


-(NSString*)regexReplacePattern:(NSString*)pattern with:(NSString*)replace
{
  NSError *error = nil;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                         options:NSRegularExpressionCaseInsensitive
                                                                           error:&error];
  NSString* modifiedString = [regex stringByReplacingMatchesInString:self
                                                             options:0
                                                               range:NSMakeRange(0, self.length)
                                                        withTemplate:replace];
  return modifiedString;
}

@end
