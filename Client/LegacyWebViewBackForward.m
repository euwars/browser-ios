#import "LegacyWebViewBackForward.h"

@interface LegacyBackForwardListItem()
@end


@implementation LegacyBackForwardListItem 

- (NSURL*)url
{
  return self.writableUrl;
}

- (NSURL*)initialUrl
{
  return self.writableInitialUrl;
}

- (NSString*)title
{
  return self.writableTitle;
}
//
//- (void)writableSetUrl:(NSURL*)url
//{
//  self.writableUrl = url;
//}
//
//- (void)writableInitialUrl:(NSURL*)initial
//{
//  self.writableInitialUrl = initial;
//}
//
//- (void)writableTitle:(NSString*)title
//{
//  self.writableTitle = tit
//}


@end

@interface LegacyBackForwardList()
@property (nonatomic, strong) NSMutableArray<LegacyBackForwardListItem*>* writableForwardBackList;
@property (nonatomic) unsigned long currentIndex;
@end


@implementation LegacyBackForwardList

- (void)goBack
{
  if (self.currentIndex > 0)
    self.currentIndex--;
}

- (void)goForward
{
  if (self.currentIndex < self.writableForwardBackList.count - 1)
    self.currentIndex++;
}

- (void)pushItem:(LegacyBackForwardListItem *)item
{
  if (self.writableForwardBackList.count > self.currentIndex + 2) {
    [self.writableForwardBackList removeObjectsInRange:
     NSMakeRange(self.currentIndex + 1, self.writableForwardBackList.count - self.currentIndex + 1)];
  }
  [self.writableForwardBackList addObject:item];
  self.currentIndex = self.writableForwardBackList.count - 1;
}

- (NSMutableArray*)writableForwardBackList
{
  if (!_writableForwardBackList) {
    _writableForwardBackList = [NSMutableArray array];
  }
  return _writableForwardBackList;
}

- (WKBackForwardListItem*)currentItem
{
  return [self itemAtIndex:self.currentIndex];
}

- (WKBackForwardListItem*)backItem
{
  return [self itemAtIndex:self.currentIndex - 1];
}

- (WKBackForwardListItem*)forwardItem
{
  return [self itemAtIndex:self.currentIndex + 1];
}

- (WKBackForwardListItem*)itemAtIndex:(NSInteger)index
{
  LegacyBackForwardListItem* item = (self.writableForwardBackList.count > 0 &&
         index < self.writableForwardBackList.count &&
         index > -1) ?
         self.writableForwardBackList[index] : nil;
  return item;
}

- (NSArray<WKBackForwardListItem*>*)backList
{
  return [NSArray array];
}

-(NSArray<WKBackForwardListItem*>*) forwardList
{
  return [NSArray array];
}

@end