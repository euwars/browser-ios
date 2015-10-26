#import "NSObject+AddAssociatedObject.h"
#import <objc/runtime.h>


@implementation NSObject (AssociatedObject)
@dynamic associatedObject;

- (void)setAssociatedObject:(id)object
{
  objc_setAssociatedObject(self, @selector(associatedObject), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)associatedObject
{
  return objc_getAssociatedObject(self, @selector(associatedObject));
}

@end
