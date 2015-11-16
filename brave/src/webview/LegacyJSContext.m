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

- (void)installHandlerForContext:(id)_context
                     handlerName:(NSString *)handlerName
                         handler:(id<WKScriptMessageHandler>)handler
                         webView:(UIWebView *)webView
{
  JSContext* context = _context;
  NSString* script = [NSString stringWithFormat:@""
                      "if (!window.hasOwnProperty('webkit')) {"
                      "  Window.prototype.webkit = {};"
                      "  Window.prototype.webkit.messageHandlers = {};"
                      "}"
                      "if (!window.webkit.messageHandlers.hasOwnProperty('%@'))"
                      "  Window.prototype.webkit.messageHandlers.%@ = {};",
                      handlerName, handlerName];

  [context evaluateScript:script];

  __block NSURLRequest* request = webView.request.copy;
  context[@"Window"][@"prototype"][@"webkit"][@"messageHandlers"][handlerName][@"postMessage"] =
  ^(NSDictionary* message) {
    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef DEBUG
      //NSLog(@"%@ %@", handlerName, message);
#endif
      LegacyScriptMessage* msg = [LegacyScriptMessage new];
      msg.writeableBody = message;
      msg.writableName = handlerName;
      msg.request = request;
      [handler userContentController:[WKUserContentController new] didReceiveScriptMessage:msg];
    });
  };
}

- (void)installHandlerForWebView:(UIWebView *)webView
                     handlerName:(NSString *)handlerName
                         handler:(id<WKScriptMessageHandler>)handler
{
  assert([NSThread isMainThread]);
  JSContext* context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
  [self installHandlerForContext:context handlerName:handlerName handler:handler webView:webView];
}

- (void)callOnContext:(id)context script:(NSString*)script
{
  JSContext* ctx = context;
  [ctx evaluateScript:script];
}

- (NSArray *)findNewFramesForWebView:(UIWebView *)webView withFrameContexts:(NSSet*)contexts
{
  NSArray *frames = [webView valueForKeyPath:@"documentView.webView.mainFrame.childFrames"];
  NSMutableArray *result = [NSMutableArray array];

  [frames enumerateObjectsUsingBlock:^(id frame, NSUInteger idx, BOOL *stop ) {
    JSContext *context = [frame valueForKeyPath:@"javaScriptContext"];
    if (! [contexts containsObject:[NSNumber numberWithUnsignedInteger:context.hash]]) {
      [result addObject:context];
    }
  }];
  return result;
}

@end
