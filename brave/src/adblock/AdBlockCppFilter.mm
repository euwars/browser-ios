/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "AdBlockCppFilter.h"
#include "ABPFilterParser.h"

static ABPFilterParser parser;

@interface AdBlockCppFilter()
@property (nonatomic, retain) NSData *data;
@end

@implementation AdBlockCppFilter

-(void)setAdblockDataFile:(NSData *)data
{
    @synchronized(self) {
        self.data = data;
        parser.deserialize((char *)self.data.bytes);
    }
}

-(BOOL)hasAdblockDataFile
{
    @synchronized(self) {
        return self.data != nil;
    }
}

+ (instancetype)singleton
{
    static AdBlockCppFilter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (BOOL)checkWithCppABPFilter:(NSString *)url
              mainDocumentUrl:(NSString *)mainDoc
             acceptHTTPHeader:(NSString *)acceptHeader
{
    if (![self hasAdblockDataFile]) {
        return false;
    }

    FilterOption option = FONoFilterOption;
    if (acceptHeader) {
        if ([acceptHeader rangeOfString:@"/css"].location != NSNotFound) {
            option  = FOStylesheet;
        }
        else if ([acceptHeader rangeOfString:@"image/"].location != NSNotFound) {
            option  = FOImage;
        }
        else if ([acceptHeader rangeOfString:@"javascript"].location != NSNotFound) {
            option  = FOScript;
        }
    }
    if (option == FONoFilterOption) {
        if ([url hasSuffix:@".js"]) {
            option = FOScript;
        }
        else if ([url hasSuffix:@".png"] || [url hasSuffix:@".jpg"] || [url hasSuffix:@".jpeg"] || [url hasSuffix:@".gif"]) {
            option = FOImage;
        }
        else if ([url hasSuffix:@".css"]) {
            option = FOStylesheet;
        }
    }

    return parser.matches(url.UTF8String, option, mainDoc.UTF8String);
}

@end
