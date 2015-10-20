#import "LegacyJSContext.h"
#import <JavaScriptCore/JavaScriptCore.h>

@implementation LegacyJSContext

-(void)foo:(UIWebView*)webview handlerName:(NSString*)handlerName
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
    NSLog(@"%@ %@", handlerName,message);
  };


}

@end
