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



#import "FRAOathMechanismFactory.h"
#import "FRAMechanismFactory.h"
#import "FRAOathMechanism.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityModel.h"
#import "FRAQRUtils.h"

#include "base32.h"
#include <CommonCrypto/CommonHMAC.h>
//#include <sys/time.h>

@implementation FRAOathMechanismFactory
    
#pragma mark -
#pragma mark Fractory Methods

- (FRAMechanism *) buildMechanism:(NSURL *)uri database:(FRAIdentityDatabase *)database model:(FRAIdentityModel *)model {
    
    NSString* _type = [uri host];
    if (nil == _type) {
        return nil; // TODO: Error handeling integration
    }
    
    NSDictionary *query = [self readQRCode:uri];
    if (nil == query) {
        return nil; // TODO: Error handeling integration
    }

    CCHmacAlgorithm algo = parseAlgo([query objectForKey:@"algorithm"]);
    NSData* key = parseKey([query objectForKey:@"secret"]);
    NSUInteger _digits = parseDigits([query objectForKey:@"digits"]);
    NSString* p = [query objectForKey:@"period"];
    NSString* image = [query objectForKey:@"image"];
    NSString* issuer = [query objectForKey:@"_issuer"];
    NSString* label = [query objectForKey:@"_label"];
    NSString* c = [query objectForKey:@"counter"];
    NSString* bgColor = [query objectForKey:@"b"];
    if(nil == key || nil == issuer || nil == label) {
        return nil; // TODO: Error handling integration
    }
    
    // TODO: handle Errors or nil values for mechanism and identity
    FRAMechanism *mechanism = [self makeMechanimsObject:database
                                                   algo:algo
                                                    key:key
                                                 digits:_digits
                                           periodString:p
                                                   type:_type
                                          counterString:c];
    FRAIdentity *identity = [self getIdentity:uri database:database image:image issuer:issuer label:label backgroundColor:bgColor];
    FRAIdentity *search = [model identityWithIssuer:[identity issuer] accountName:[identity accountName]];
    if (search == nil) {
        @autoreleasepool {
            NSError* error;
            [model addIdentity:identity error:&error];
        }
    } else {
        identity = search;
        if ([self checkForDuplicate:identity mechanism:mechanism]) {
            // TODO: populate NSError
            return nil;
        }
    }
    
    @autoreleasepool {
        NSError* error;
        [identity addMechanism:mechanism error:&error];
    }
    
    return mechanism;
}

- (NSDictionary *) readQRCode:(NSURL *)uri {
    NSString* scheme = [uri scheme];
    if (scheme == nil || !([scheme isEqualToString:@"otpauth"] || [scheme isEqualToString:@"pushauth"])) {
        return nil;
    }
    NSString* _type = [uri host];
    if (_type == nil || (![_type isEqualToString:@"totp"] && ![_type isEqualToString:@"hotp"])) {
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
    
    return query;
}

- (bool) checkForDuplicate:(FRAIdentity *)identity mechanism:(FRAMechanism *)mechanism{
    return false;
}

/*!
 * Make a mechanism from the required data
 */
- (FRAMechanism *) makeMechanimsObject:(FRAIdentityDatabase *)database
                                  algo:(CCHmacAlgorithm)algo
                                   key:(NSData *)key
                                digits:(NSUInteger)digits
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
    if ([type isEqualToString:@"hotp"]) {
        counter = counterString != nil ? [counterString longLongValue] : 0;
    }
    
    // TODO: Implicit conversion loses integer precision: 'uint64_t' (aka 'unsigned long long')
    //       to 'NSUInteger' (aka 'unsigned int')
    return [FRAOathMechanism oathMechanismWithDatabase:database type:type usingSecretKey:key andHMACAlgorithm:algo withKeyLength:digits andEitherPeriod:period orCounter:counter];
}

/*!
 * Resolves the Identity from the URL that has been provided.
 * @return an initialised but not persisted Identity.
 */
- (FRAIdentity *)getIdentity:(NSURL*)uri database:(FRAIdentityDatabase *)database image:(NSString *)image issuer:(NSString *)issuer label:(NSString *)label backgroundColor:(NSString*)bgColor{
    // Get image
    // TODO: get real image from url
    NSURL* _image = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"forgerock-logo" ofType:@"png"]];
    
    return [FRAIdentity identityWithDatabase:database accountName:label issuer:issuer image:_image backgroundColor:bgColor];
}

- (bool) supports:(NSURL *)uri {
    NSString* scheme = [uri scheme];
    // TODO: Currently hardcoded to one scheme, upgrade to support multiple.
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