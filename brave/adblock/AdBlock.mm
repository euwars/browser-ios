#import "Adblock.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "NSURL+Matcher.h"
#import "DisconnectDict.m"
//#import "Client-Swift.h"

#include "ABPFilterParser.h"
#include <string>

// Generated with: (echo "const char* easyList = " && cat orig | sed 's|\"|\\"|g' | sed 's|\\\\"|\\\\\\"|g'  | sed 's/^/"/' | sed 's/$/\\"/' && echo ";") > easylist-as-string.cpp
#include "easylist-as-string.cpp"

@interface AdBlock()
@property (atomic, strong) NSMutableSet* replacedUrls;
@property (nonatomic, strong) NSDictionary* disconnectDomains;
@end

ABPFilterParser parser;

@implementation AdBlock

+ (instancetype)singleton
{
  static AdBlock* instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (instancetype)init
{
  if (self = [super init]) {
    self.disconnectDomains = kDisconnectDict;
    self.replacedUrls = [NSMutableSet set];
  }
  return self;
}


int callcount = 0;
- (BOOL)shouldBlock:(NSURLRequest*)request
{
  @synchronized(self){
    static BOOL ranonce = NO;
    static NSMutableDictionary* cachedResults;
    if (!ranonce) {
      ranonce = YES;
      cachedResults = [NSMutableDictionary dictionary];

      parser.parse(easyList);
    }

    NSString* url = request.URL.absoluteString;
    NSString* domain = request.mainDocumentURL.host;
    if (!domain)
      return NO;

    if ([domain isEqualToString:request.URL.host]) {
      // this only stops 1% of checks, not useful
      return NO;
    }

    BOOL block = NO;

    //if (gApp().isHttpFilterDisconnectEnabled) {
//      block = [self.disconnectDomains
//               objectForKey:[request.URL hostWithGenericSubdomainPrefixRemoved]];
    //}

//    if (gApp().isHttpFilterAdblockEnabled && !block) {
//      JSValue* val = [self.funcShouldBlock.value callWithArguments:[NSArray arrayWithObjects:url, domain, nil]];
//      block = [val toBool];
//    }

    block = [self checkWithCppABPFilter:url mainDocumentUrl:domain];
    if (block) {
      NSLog(@"block %@", request.URL.absoluteString);
      [self.replacedUrls addObject:request.URL];
      [[NSNotificationCenter defaultCenter] postNotificationName:kNotification_adBlocked
                                                          object:self
                                                        userInfo:@{@"url":request.URL}];
    }

    callcount++;
    //NSLog(@"%d", callcount);

    return block;
  }
}

- (NSString*)getBlockedAsJSArray
{
  if (self.replacedUrls.count < 1)
    return @"[]";

  NSMutableString* result = [NSMutableString stringWithString:@"["];
  for (NSURL* url in self.replacedUrls) {
    [result appendFormat:@"'%@',", url.absoluteString];
  }
  [result deleteCharactersInRange:NSMakeRange(result.length - 1, 1)];
  [result appendString:@"]"];
  return result;
}


- (BOOL)isAlreadyBlockedUrl:(NSURL*)url
{
  for (NSURL* replaced in self.replacedUrls) {
    if ([replaced.absoluteString isEqualToString:url.absoluteString]) {
      return true;
    }
  }
  return false;
}

- (BOOL)checkWithCppABPFilter:(NSString*)url mainDocumentUrl:(NSString*)mainDoc
{
  return parser.matches(url.UTF8String, FONoFilterOption, mainDoc.UTF8String);
}

@end
