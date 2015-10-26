@import WebKit;
@import UIKit;

@interface LegacyJSContext : NSObject

-(void)installHandlerForWebView:(UIWebView*)wv
                    handlerName:(NSString*)handlerName
                        handler:(id<WKScriptMessageHandler>)handler;

@end
