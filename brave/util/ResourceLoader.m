
#import "ResourceLoader.h"

@implementation ResourceLoader
+ (NSString*)stringForFile:(NSString*)name ofType:(NSString*)type inDir:(NSString *)dir
{
  name = [dir stringByAppendingPathComponent:name];
  NSString* filePath = [[NSBundle mainBundle] pathForResource:name ofType:type];
  assert(filePath);
  NSError* error = nil;
  NSString* content = [NSString stringWithContentsOfFile:filePath
                                                encoding:NSUTF8StringEncoding
                                                   error:&error];
  if (error) {
    NSLog(@"Error %@: %@", [[self class] description], error.description);
  }
  assert(content);
  return content;
}

@end
