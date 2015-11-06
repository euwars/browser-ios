@import WebKit;
@import UIKit;



@interface LegacyJSContext : NSObject

+(void)setup;

-(void)installHandlerForWebView:(UIWebView *)wv
                    handlerName:(NSString *)handlerName
                        handler:(id<WKScriptMessageHandler>)handler;

- (void)installHandlerForContext:(id)context
                     handlerName:(NSString *)handlerName
                         handler:(id<WKScriptMessageHandler>)handler
                         webView:(UIWebView *)webView;

- (void)callOnContext:(id)context script:(NSString*)script;

-(NSArray*)findNewFramesForWebView:(UIWebView *)webView withFrameContexts:(NSSet *)contexts;

@end
