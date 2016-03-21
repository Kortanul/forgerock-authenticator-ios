/*
 * The contents of this file are subject to the terms of the Common Development and
 * Distribution License (the License). You may not use this file except in compliance with the
 * License.
 *
 * You can obtain a copy of the License at legal/CDDLv1.0.txt. See the License for the
 * specific language governing permission and limitations under the License.
 *
 * When distributing Covered Software, include this CDDL Header Notice in each file and include
 * the License file at legal/CDDLv1.0.txt. If applicable, add the following below the CDDL
 * Header, with the fields enclosed by brackets [] replaced by your own identifying
 * information: "Portions copyright [year] [name of copyright owner]".
 *
 * Copyright 2016 ForgeRock AS.
 *
 * Portions Copyright 2014 Nathaniel McCallum, Red Hat
 */

#import "FRAOathMechanism.h"
#import "base32.h"

#import <CommonCrypto/CommonHMAC.h>
#import <sys/time.h>

static BOOL ishex(char c) {
    if (c >= '0' && c <= '9') {
        return YES;
    }
    if (c >= 'A' && c <= 'F') {
        return YES;
    }
    if (c >= 'a' && c <= 'f') {
        return YES;
    }
    return NO;
}

static uint8_t fromhex(char c) {
    if (c >= '0' && c <= '9') {
        return c - '0';
    }
    if (c >= 'A' && c <= 'F') {
        return c - 'A' + 10;
    }
    if (c >= 'a' && c <= 'f') {
        return c - 'a' + 10;
    }
    return 0;
}

static NSString* decode(const NSString* str) {
    if (str == nil) {
        return nil;
    }
    const char *tmp = [str UTF8String];
    NSMutableString *ret = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < str.length; i++) {
        if (tmp[i] != '%' || !ishex(tmp[i + 1]) || !ishex(tmp[i + 2])) {
            [ret appendFormat:@"%c", tmp[i]];
            continue;
        }
        
        uint8_t c = 0;
        c |= fromhex(tmp[++i]) << 4;
        c |= fromhex(tmp[++i]);
        
        [ret appendFormat:@"%c", c];
    }
    
    return ret;
}

static NSData* parseKey(const NSString *secret) {
    uint8_t key[4096];
    if (secret == nil) {
        return nil;
    }
    const char *tmp = [secret cStringUsingEncoding:NSASCIIStringEncoding];
    if (tmp == NULL) {
        return nil;
    }
    int res = base32_decode(tmp, key, sizeof(key));
    if (res < 0 || res == sizeof(key)) {
        return nil;
    }
    return [NSData dataWithBytes:key length:res];
}

static CCHmacAlgorithm parseAlgo(const NSString* algo) {
    static struct {
        const char *name;
        CCHmacAlgorithm num;
    } algomap[] = {
        { "md5", kCCHmacAlgMD5 },
        { "sha1", kCCHmacAlgSHA1 },
        { "sha256", kCCHmacAlgSHA256 },
        { "sha512", kCCHmacAlgSHA512 },
    };
    if (algo == nil) {
        return kCCHmacAlgSHA1;
    }
    const char *calgo = [algo cStringUsingEncoding:NSUTF8StringEncoding];
    if (calgo == NULL) {
        return kCCHmacAlgSHA1;
    }
    for (int i = 0; i < sizeof(algomap) / sizeof(algomap[0]); i++) {
        if (strcasecmp(calgo, algomap[i].name) == 0) {
            return algomap[i].num;
        }
    }
    
    return kCCHmacAlgSHA1;
}

static NSInteger parseDigits(const NSString* digits) {
    if (digits == nil) {
        return 6;
    }
    NSInteger val = [digits integerValue];
    if (val != 6 && val != 8) {
        return 6;
    }
    return val;
}

static inline size_t getDigestLength(CCHmacAlgorithm algo) {
    switch (algo) {
        case kCCHmacAlgMD5:
            return CC_MD5_DIGEST_LENGTH;
        case kCCHmacAlgSHA256:
            return CC_SHA256_DIGEST_LENGTH;
        case kCCHmacAlgSHA512:
            return CC_SHA512_DIGEST_LENGTH;
        case kCCHmacAlgSHA1:
        default:
            return CC_SHA1_DIGEST_LENGTH;
    }
}

static NSString* getHOTP(CCHmacAlgorithm algo, uint8_t digits, NSData* key, uint64_t counter) {
#ifdef __LITTLE_ENDIAN__
    // Network byte order
    counter = (((uint64_t) htonl(counter)) << 32) + htonl(counter >> 32);
#endif
    
    // Create digits divisor
    uint32_t div = 1;
    for (int i = digits; i > 0; i--) {
        div *= 10;
    }
    // Create the HMAC
    uint8_t digest[getDigestLength(algo)];
    CCHmac(algo, [key bytes], [key length], &counter, sizeof(counter), digest);
    
    // Truncate
    uint32_t binary;
    uint32_t off = digest[sizeof(digest) - 1] & 0xf;
    binary  = (digest[off + 0] & 0x7f) << 0x18;
    binary |= (digest[off + 1] & 0xff) << 0x10;
    binary |= (digest[off + 2] & 0xff) << 0x08;
    binary |= (digest[off + 3] & 0xff) << 0x00;
    binary  = binary % div;
    
    return [NSString stringWithFormat:[NSString stringWithFormat:@"%%0%hhulu", digits], binary];
}

@implementation FRAOathMechanism {
    CCHmacAlgorithm algo;
    NSData*   key;
    uint64_t counter;
    uint32_t period;
}

- (id)initWithURL:(NSURL*)url {
    if (!(self = [super init])) {
        return nil;
    }
    NSString* scheme = [url scheme];
    if (scheme == nil || ![scheme isEqualToString:@"otpauth"]) {
        return nil;
    }
    _type = [url host];
    if (_type == nil || (![_type isEqualToString:@"totp"] && ![_type isEqualToString:@"hotp"])) {
        return nil;
    }
    // Get the path and strip it of its leading '/'
    NSString* path = [url path];
    if (path == nil) {
        return nil;
    }
    while ([path hasPrefix:@"/"]) {
        path = [path substringFromIndex:1];
    }
    if ([path length] == 0) {
        return nil;
    }
    // Get issuer and label
    NSArray* array = [path componentsSeparatedByString:@":"];
    if (array == nil || [array count] == 0) {
        return nil;
    }
    NSString* _issuer;
    NSString* _label;
    if ([array count] > 1) {
        _issuer = decode([array objectAtIndex:0]);
        _label = decode([array objectAtIndex:1]);
    } else {
        _issuer = @"";
        _label = decode([array objectAtIndex:0]);
    }
    
    // Parse query
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    array = [[url query] componentsSeparatedByString:@"&"];
    for (NSString *kv in array) {
        // Value can contain '=' symbols, so look for first symbol.
        NSRange index = [kv rangeOfString:@"="];
        if (index.location == NSNotFound) {
            continue;
        }
        NSString *name = [kv substringToIndex:index.location];
        NSString *value = [kv substringFromIndex:index.location + index.length];
        [query setValue:decode(value) forKey:name];
    }
    
    // Get key
    key = parseKey([query objectForKey:@"secret"]);
    if (key == nil) {
        return nil;
    }
    
    // Get algorithm and digits
    algo = parseAlgo([query objectForKey:@"algorithm"]);
    _digits = parseDigits([query objectForKey:@"digits"]);
    
    // Get period
    NSString *p = [query objectForKey:@"period"];
    period = p != nil ? (int) [p integerValue] : 30;
    if (period == 0) {
        period = 30;
    }
    
    // Get counter
    if ([_type isEqualToString:@"hotp"]) {
        NSString *c = [query objectForKey:@"counter"];
        counter = c != nil ? [c longLongValue] : 0;
    }
    
    // Get image
    NSURL* _image = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"forgerock-logo" ofType:@"png"]];
    
    // Set owner
    _owner = [FRAIdentity identityWithAccountName:_label issuer:_issuer image:_image];
    
    return self;
}

- (id)initWithString:(NSString*)string {
    return [self initWithURL:[[NSURL alloc] initWithString:string]];
}

- (FRAOathCode*)code {
    time_t now = time(NULL);
    if (now == (time_t) -1) {
        now = 0;
    }
    if ([_type isEqualToString:@"hotp"]) {
        NSString* code = getHOTP(algo, _digits, key, counter++);
        return [[FRAOathCode alloc] initWithCode:code startTime:now endTime:now + period];
    }
    
    FRAOathCode* next = [[FRAOathCode alloc] initWithCode:getHOTP(algo, _digits, key, now / period + 1)
                                                  startTime:now / period * period + period
                                                    endTime:now / period * period + period + period];
    return [[FRAOathCode alloc] initWithCode:getHOTP(algo, _digits, key, now / period)
                                    startTime:now / period * period
                                      endTime:now / period * period + period
                             nextTokenCode:next];
}

@end
