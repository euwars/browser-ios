#import "AdBlockCppFilter.h"
#include "ABPFilterParser.h"

ABPFilterParser parser;

@interface AdBlockCppFilter()
@property (nonatomic, retain) NSData *data;
@end

@implementation AdBlockCppFilter

static NSData *loadData()
{
  NSString *path = [[NSBundle mainBundle] pathForResource:@"ABPFilterParserData" ofType: @"dat"];
  assert(path);
  NSData *data = [NSData dataWithContentsOfFile:path];
  assert(data);
  return data;
}

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
    self.data = loadData();
    parser.deserialize((char *)self.data.bytes);
  }
  return self;
}

- (BOOL)checkWithCppABPFilter:(NSString *)url mainDocumentUrl:(NSString *)mainDoc
{
  return parser.matches(url.UTF8String, FONoFilterOption, mainDoc.UTF8String);
}

@end
