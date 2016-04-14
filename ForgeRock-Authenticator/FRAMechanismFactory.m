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

#import <Foundation/Foundation.h>

#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAMechanism.h"
#import "FRAMechanismFactory.h"
#import "FRAOathMechanism.h"

#include "base32.h"
#include <CommonCrypto/CommonHMAC.h>
#include <sys/time.h>

@implementation FRAMechanismFactory

/*!
 * Resolves the Identity from the URL that has been provided.
 * @return an initialised but not persisted Identity.
 */
- (FRAIdentity*)getIdentity:(NSURL*)url {
    NSString* scheme = [url scheme];
    // TODO: Currently hardcoded to one scheme, upgrade to support multiple.
    if (scheme == nil || ![scheme isEqualToString:@"otpauth"]) {
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
    
    // Get image
    NSURL* _image = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"forgerock-logo" ofType:@"png"]];

    return [[FRAIdentity alloc] initWithAccountName:_label issuedBy:_issuer withImage:_image];
}

- (FRAMechanism*) getMechanism:(NSURL *)url {
    NSString* scheme = [url scheme];
    if (scheme == nil || ![scheme isEqualToString:@"otpauth"]) {
        return nil;
    }
    NSString* _type = [url host];
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
    
    CCHmacAlgorithm algo;
    NSData*   key;
    uint64_t counter;
    uint32_t period;
    
    // Get key
    key = parseKey([query objectForKey:@"secret"]);
    if (key == nil) {
        return nil;
    }
    
    // Get algorithm and digits
    algo = parseAlgo([query objectForKey:@"algorithm"]);
    NSUInteger _digits = parseDigits([query objectForKey:@"digits"]);
    
    // Get period
    NSString *p = [query objectForKey:@"period"];
    period = p != nil ? (int) [p integerValue] : 30;
    if (period == 0) {
        period = 30;
    }
    
    // Get counter
    counter = 0;
    if ([_type isEqualToString:@"hotp"]) {
        NSString *c = [query objectForKey:@"counter"];
        counter = c != nil ? [c longLongValue] : 0;
    }
    
    // TODO: Implicit conversion loses integer precision: 'uint64_t' (aka 'unsigned long long')
    //       to 'NSUInteger' (aka 'unsigned int')
    return [[FRAOathMechanism alloc] initWithType:_type usingSecretKey:key andHMACAlgorithm:algo withKeyLength:_digits andEitherPeriod:period orCounter:counter];
}

- (FRAMechanism*)parseFromURL:(NSURL *)url {
    FRAMechanism* mechanism = [self getMechanism:url];

    // Find Identity in existing Identities list
    FRAIdentity* identity = [self getIdentity:url];
    FRAIdentity* search = [_database identityWithIssuer:[identity issuer] accountName:[identity accountName]];
    if (search != nil) {
        identity = search;
    }
    
    [identity addMechanism:mechanism];
    return mechanism;
}

- (FRAMechanism*) parseFromString:(NSString *)string {
    return [self parseFromURL:[[NSURL alloc]initWithString:string]];
}

#pragma mark -
#pragma mark static URL parsing functions

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

@end