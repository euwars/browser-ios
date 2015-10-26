#import "NSURL+Matcher.h"
#import "NSString+Regex.h"

@implementation NSURL (NSURL_Matcher)

- (BOOL)hasString:(NSString*) find
{
  return [self.absoluteString rangeOfString:find].location != NSNotFound;
}

- (BOOL)hasSuffix:(NSString *)find
{
  NSURLComponents* urlComponents = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];
  urlComponents.query = nil; // Strip out query parameters.
  return [urlComponents.path hasSuffix:find];
}

- (NSString*)hostWithLastTwoComponentsOnly
{
  NSArray<NSString *>* parts = [self.host componentsSeparatedByString:@"."];
  if (parts.count > 2) {
    return [[parts subarrayWithRange:NSMakeRange(1, parts.count -1)]  componentsJoinedByString:@"."];
  }
  return self.host;
}

- (NSString*)hostWithGenericSubdomainPrefixRemoved
{
  return [self.host regexReplacePattern:@"^(m\\.|www\\.|mobile\\.)" with:@""];
}

@end
