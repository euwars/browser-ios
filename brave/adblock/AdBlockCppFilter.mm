#import "AdBlockCppFilter.h"
#include "ABPFilterParser.h"

// Generated with:
// (echo echo "const char* easyList = " && cat orig | sed 's|\\|\\\\|g' | sed 's|\"|\\"|g' | sed 's/^/"/' | sed 's|$|\\n"|' && echo ";") > easylist-as-string.cpp
#include "easylist-as-string.cpp"

ABPFilterParser parser;

@implementation AdBlockCppFilter

+ (instancetype)singleton
{
  static AdBlockCppFilter *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (instancetype)init
{
  if (self = [super init]) {
    parser.parse(easyList);
  }
  return self;
}

- (BOOL)checkWithCppABPFilter:(NSString *)url mainDocumentUrl:(NSString *)mainDoc
{
  return parser.matches(url.UTF8String, FONoFilterOption, mainDoc.UTF8String);
}

@end
