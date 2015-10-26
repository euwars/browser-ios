// NSString+SHA1
// Created by William Denniss
// Public domain. No rights reserved.

#import "NSString+SHA1.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (SHA1)

// function to generate sha1 hashes that match the output of PHP's sha1 method
- (NSString*) sha1
{
	// code snippet from http://stackoverflow.com/a/1084497/72176

	// This is the destination
	uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
	// This one function does an unkeyed SHA1 hash of your hash data
	CC_SHA1(self.bytes, self.length, digest);

	// Now convert to NSData structure to make it usable again
	NSData* out = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
	// description converts to hex but puts <> around it and spaces every 4 bytes
	NSString* hash = [out description];
	hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
	hash = [hash stringByReplacingOccurrencesOfString:@"<" withString:@""];
	hash = [hash stringByReplacingOccurrencesOfString:@">" withString:@""];
	// hash is now a string with just the 40char hash value in it

	return hash;
}

@end

@implementation NSString (SHA1)

// function to generate sha1 hashes that match the output of PHP's sha1 method
- (NSString*) sha1
{
	NSString* hashkey = self;

	// PHP uses ASCII encoding, not UTF
	const char* s = [hashkey cStringUsingEncoding:NSASCIIStringEncoding];
	NSData* keyData = [NSData dataWithBytes:s length:strlen(s)];

	return [keyData sha1];
}

@end
