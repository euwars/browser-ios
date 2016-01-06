/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@import WebKit;
@import UIKit;


@interface LegacyJSContext : NSObject

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
