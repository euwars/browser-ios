#import "LegacyJSContext.h"
#import <JavaScriptCore/JavaScriptCore.h>


@interface FrameInfoWrapper : WKFrameInfo
@property (atomic, retain) NSURLRequest* writableRequest;
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
@property (atomic, retain) NSObject* writeableBody;
@property (atomic, copy) NSString* writableName;
@property (atomic, retain) NSURLRequest* request;
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
  @synchronized(self) {
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
      dispatch_async(dispatch_get_main_queue(), ^{
#ifdef DEBUG
       // NSLog(@"%@ %@", handlerName, message);
#endif
        LegacyScriptMessage* msg = [LegacyScriptMessage new];
        msg.writeableBody = message;
        msg.writableName = handlerName;
        msg.request = webview.request;
        [handler userContentController:[WKUserContentController new] didReceiveScriptMessage:msg];
      });
    };
  }
}

@end
