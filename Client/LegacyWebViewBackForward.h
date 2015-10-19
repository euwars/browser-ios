#import <WebKit/WebKit.h>

@interface LegacyBackForwardListItem : WKBackForwardListItem
@property (nonatomic, strong) NSURL* writableUrl;
@property (nonatomic, strong) NSURL* writableInitialUrl;
@property (nonatomic, copy) NSString* writableTitle;

- (NSURL*)url;
- (NSURL*)initialUrl;
- (NSString*)title;


@end

@interface LegacyBackForwardList : WKBackForwardList
- (void)pushItem:(LegacyBackForwardListItem*)item;
- (void)goBack;
- (void)goForward;
@end