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
 */

#include "base32.h"
#include <CommonCrypto/CommonHMAC.h>

#import "FRAError.h"
#import "FRAHotpOathMechanism.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityModel.h"
#import "FRAMechanismFactory.h"
#import "FRAOathMechanismFactory.h"
#import "FRAQRUtils.h"
#import "FRATotpOathMechanism.h"

static BOOL SUCCESS = YES;

@implementation FRAOathMechanismFactory
    
#pragma mark -
#pragma mark Fractory Methods

- (FRAMechanism *) buildMechanism:(NSURL *)uri database:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel handler:(void (^)(BOOL, NSError *))handler error:(NSError *__autoreleasing *)error {
    
    NSDictionary *query = [self readQRCode:uri];

    CCHmacAlgorithm algo = parseAlgo([query objectForKey:@"algorithm"]);
    NSData *key = parseKey([query objectForKey:@"secret"]);
    NSUInteger _digits = parseDigits([query objectForKey:@"digits"]);
    NSString *period = [query objectForKey:@"period"];
    NSString *image = [query objectForKey:@"image"];
    NSString *issuer = [query objectForKey:@"_issuer"];
    NSString *label = [query objectForKey:@"_label"];
    NSString *counter = [query objectForKey:@"counter"];
    NSString *bgColor = [query objectForKey:@"b"];
    NSString *_type = [query objectForKey:@"_type"];
    
    if((key.length <= 0) || ![self isValid:issuer] || ![self isValid:label]) {
        *error = [FRAError createError:NSLocalizedString(@"Invalid QR code", nil) code:FRAInvalidQRCode];
        return nil;
    }
 
    FRAMechanism *mechanism = [self makeMechanimsObject:database
                                          identityModel:identityModel
                                              algorithm:algo
                                                    key:key
                                             codeLength:_digits
                                           periodString:period
                                                   type:_type
                                          counterString:counter];

    FRAIdentity *identity = [self identityWithIssuer:issuer accountName:label identityModel:identityModel backgroundColor:bgColor image:image database:database error:error];

    if (![identity addMechanism:mechanism error:error]) {
        return nil;
    }
    
    [self invokeCompletionHandler:handler];
    
    return mechanism;
}

- (NSDictionary *) readQRCode:(NSURL *)uri {
    NSString* scheme = [uri scheme];
    if (scheme == nil || !([scheme isEqualToString:@"otpauth"] || [scheme isEqualToString:@"pushauth"])) {
        return nil;
    }
    NSString* _type = [uri host];
    if (_type == nil || (![_type isEqualToString:[FRATotpOathMechanism mechanismType]] && ![_type isEqualToString:[FRAHotpOathMechanism mechanismType]])) {
        return nil;
    }
    // Get the path and strip it of its leading '/'
    NSString* path = [uri path];
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
        _issuer = [FRAQRUtils decode:[array objectAtIndex:0]];
        _label = [FRAQRUtils decode:[array objectAtIndex:1]];
    } else {
        _issuer = @"";
        _label = [FRAQRUtils decode:[array objectAtIndex:0]];
    }
    
    // Parse query
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    array = [[uri query] componentsSeparatedByString:@"&"];
    for (NSString *kv in array) {
        // Value can contain '=' symbols, so look for first symbol.
        NSRange index = [kv rangeOfString:@"="];
        if (index.location == NSNotFound) {
            continue;
        }
        NSString *name = [kv substringToIndex:index.location];
        NSString *value = [kv substringFromIndex:index.location + index.length];
        [query setValue:[FRAQRUtils decode:value] forKey:name];
    }
    
    [query setValue:_issuer forKey:@"_issuer"];
    [query setValue:_label forKey:@"_label"];
    [query setValue:_type forKey:@"_type"];
    
    return query;
}

/*!
 * Checks if a string is not null and not empty.
 */
- (BOOL)isValid:(NSString *)info {
    return info.length > 0;
}

/*!
 * Make a mechanism from the required data
 */
- (FRAMechanism *) makeMechanimsObject:(FRAIdentityDatabase *)database
                         identityModel:(FRAIdentityModel *)identityModel
                             algorithm:(CCHmacAlgorithm)algorithm
                                   key:(NSData *)key
                            codeLength:(NSUInteger)codeLength
                          periodString:(NSString *)periodString
                                  type:(NSString *)type
                         counterString:(NSString *)counterString {
    // verify
    if (key == nil) {
        return nil;
    }
    // get period
    uint32_t period;
    if (nil == periodString) {
        period = 30;
    } else {
        period = [periodString intValue];
    }
    if (0 == period) {
        period = 30;
    }
    
    // Get counter
    uint64_t counter = 0;
    if ([type isEqualToString:[FRAHotpOathMechanism mechanismType]]) {
        counter = counterString != nil ? [counterString longLongValue] : 0;
    }
    
    if ([type isEqualToString:[FRAHotpOathMechanism mechanismType]]) {
        return [FRAHotpOathMechanism mechanismWithDatabase:database identityModel:identityModel secretKey:key HMACAlgorithm:algorithm codeLength:codeLength counter:counter];
    } else {
        return [FRATotpOathMechanism mechanismWithDatabase:database identityModel:identityModel secretKey:key HMACAlgorithm:algorithm codeLength:codeLength period:period];
    }
    
}

- (FRAIdentity *)identityWithIssuer:(NSString *)issuer accountName:(NSString *)accountName identityModel:(FRAIdentityModel *)identityModel backgroundColor:(NSString *)backgroundColor image:(NSString *)image database:(FRAIdentityDatabase *)database error:(NSError *__autoreleasing *)error {
    
    FRAIdentity *identity = [identityModel identityWithIssuer:issuer accountName:accountName];
    if (!identity) {
        identity = [FRAIdentity identityWithDatabase:database identityModel:identityModel accountName:accountName issuer:issuer image:[NSURL URLWithString:image] backgroundColor:backgroundColor];
        if (![identityModel addIdentity:identity error:error]) {
            return nil;
        }
    }

    return identity;
}

- (void)invokeCompletionHandler:(void (^)(BOOL, NSError *))handler {
    if (handler) {
        handler(SUCCESS, nil);
    }
}

- (bool) supports:(NSURL *)uri {
    NSString* scheme = [uri scheme];
    if (scheme == nil || ![scheme isEqualToString:@"otpauth"]) {
        return false;
    }
    return true;
}

- (NSString *) getSupportedProtocol {
    return @"otpauth";
}

#pragma mark -
#pragma mark static URL parsing functions

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