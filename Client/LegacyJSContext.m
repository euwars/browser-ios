#import "LegacyJSContext.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface LegacyScriptMessage: WKScriptMessage
@property (nonatomic, retain) NSObject* writeableBody;
@property (nonatomic, copy) NSString* writableName;
@end
@implementation LegacyScriptMessage

-(id)body
{
  return self.writeableBody;
}

- (NSString*)name
{
  return self.writableName;
}
@end

@implementation LegacyJSContext
-(void)installHandlerForWebView:(UIWebView *)webview
                    handlerName:(NSString *)handlerName
                        handler:(id<WKScriptMessageHandler>)handler
{
  [webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@""
   "if (!window.hasOwnProperty('webkit')) {"
     "Window.prototype.webkit = {};"
     "Window.prototype.webkit.messageHandlers = {};"
   "}"
   "if (!window.webkit.messageHandlers.hasOwnProperty('%@'))"
   "  Window.prototype.webkit.messageHandlers.%@ = {};", handlerName, handlerName]
   ];

  JSContext* context = [webview valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];

  context[@"Window"][@"prototype"][@"webkit"][@"messageHandlers"][handlerName][@"postMessage"] =
  ^(NSDictionary* message) {
    NSLog(@"%@ %@", handlerName, message);
    LegacyScriptMessage* msg = [LegacyScriptMessage new];
    msg.writeableBody = message;
    msg.writableName = handlerName;
    [handler userContentController:[WKUserContentController new] didReceiveScriptMessage:msg];
  };


}

@end
