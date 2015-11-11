
#import "UIView+ShowBorders.h"
#import <UIKit/UIKit.h>
#import "Swizzling.h"

@implementation UIView(ShowBorders)

- (instancetype)_initWithFrame:(CGRect)frame
{
  UIView *obj = [self _initWithFrame:frame];
  obj.layer.borderWidth = 0.5;
  obj.layer.borderColor = [[UIColor redColor] CGColor];
  return obj;
}

+ (void)bordersOn
{
  SwizzleInstanceMethods(self, @selector(initWithFrame:),
                         @selector(_initWithFrame:));
}

@end
