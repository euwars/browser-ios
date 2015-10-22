#import "LegacyJSContext.h"
#import <JavaScriptCore/JavaScriptCore.h>


@interface FrameInfoWrapper : WKFrameInfo
@property (nonatomic, retain) NSURLRequest* writableRequest;
@end

@implementation FrameInfoWrapper

-(NSURLRequest*)request
{
  return self.writableRequest;
}

-(BOOL)isMainFrame
{
  return true;
}

@end

@interface LegacyScriptMessage: WKScriptMessage
@property (nonatomic, retain) NSObject* writeableBody;
@property (nonatomic, copy) NSString* writableName;
@property (nonatomic, retain) NSURLRequest* request;
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

-(WKFrameInfo *)frameInfo
{
  FrameInfoWrapper* f = [FrameInfoWrapper new];
  f.writableRequest = self.request;
  return f;
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
#ifdef DEBUG
    //NSLog(@"%@ %@", handlerName, message);
#endif
    LegacyScriptMessage* msg = [LegacyScriptMessage new];
    msg.writeableBody = message;
    msg.writableName = handlerName;
    msg.request = webview.request;
    [handler userContentController:[WKUserContentController new] didReceiveScriptMessage:msg];
  };


}

@end
