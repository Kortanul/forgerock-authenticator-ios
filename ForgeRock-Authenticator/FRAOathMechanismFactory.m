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

    NSNumber *algorithm = parseAlgorithm([query objectForKey:@"algorithm"]);
    NSData *key = parseKey([query objectForKey:@"secret"]);
    NSNumber *_digits = parseDigits([query objectForKey:@"digits"]);
    NSNumber *period = parsePeriod([query objectForKey:@"period"]);
    NSString *image = [query objectForKey:@"image"];
    NSString *label = [query objectForKey:@"_label"];
    NSString *issuer = parseIssuer([query objectForKey:@"_issuer"], [query objectForKey:@"issuer"], label);
    NSNumber *counter = parseCounter([query objectForKey:@"counter"]);
    NSString *backgroundColor = [query objectForKey:@"b"];
    NSString *_type = [query objectForKey:@"_type"];
    
    if(![self hasValidType:_type key:key issuer:issuer counter:counter algorithm:algorithm digits:_digits period:period backgroundColor:backgroundColor]) {
        if (error) {
            *error = [FRAError createError:NSLocalizedString(@"Invalid QR code", nil) code:FRAInvalidQRCode];
        }
        return nil;
    }
 
    FRAMechanism *mechanism = [self makeMechanimsObject:database
                                          identityModel:identityModel
                                              algorithm:algorithm.intValue
                                                    key:key
                                             codeLength:_digits.intValue
                                                 period:period.intValue
                                                   type:_type
                                                counter:counter.integerValue];

    FRAIdentity *identity = [self identityWithIssuer:issuer accountName:label identityModel:identityModel backgroundColor:backgroundColor image:image database:database error:error];

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
    if (_type == nil || (![self isTotp:_type] && ![self isHotp:_type])) {
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
 * Checks if parameters are valid.
 */
- (BOOL)hasValidType:(NSString *)type
                 key:(NSData *)key
              issuer:(NSString *)issuer
             counter:(NSNumber *)counter
           algorithm:(NSNumber *)algorithm
              digits:(NSNumber *)digits
              period:(NSNumber *)period
     backgroundColor:(NSString *)backgroundColor {
    if (!algorithm || key.length == 0 || !digits || (issuer.length == 0) || !isValidBackgroundColor(backgroundColor)) {
        return NO;
    }
    
    if ([self isHotp:type]) {
        return counter;
    }
    
    return period;
}

/*!
 * Checks if mechanism type is HOTP.
 */
- (BOOL)isHotp:(NSString *)type {
    return [[type lowercaseString] isEqualToString:[FRAHotpOathMechanism mechanismType]];
}

/*!
 * Checks if mechanism type is TOTP.
 */
- (BOOL)isTotp:(NSString *)type {
    return [[type lowercaseString] isEqualToString:[FRATotpOathMechanism mechanismType]];
}

/*!
 * Make a mechanism from the required data
 */
- (FRAMechanism *) makeMechanimsObject:(FRAIdentityDatabase *)database
                         identityModel:(FRAIdentityModel *)identityModel
                             algorithm:(CCHmacAlgorithm)algorithm
                                   key:(NSData *)key
                            codeLength:(NSUInteger)codeLength
                                period:(u_int32_t)period
                                  type:(NSString *)type
                               counter:(NSUInteger)counter {


    if ([self isHotp:type]) {
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

- (bool)supports:(NSURL *)uri {
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

static NSNumber* parseAlgorithm(const NSString *algorithm) {
    if (algorithm.length == 0) {
        return [NSNumber numberWithInt:kCCHmacAlgSHA1];
    }
    
    NSDictionary<NSString *, NSNumber *> *supportedAlgorithms = @{@"md5": [NSNumber numberWithInt:kCCHmacAlgMD5],
                                                                  @"sha1": [NSNumber numberWithInt:kCCHmacAlgSHA1],
                                                                  @"sha256": [NSNumber numberWithInt:kCCHmacAlgSHA256],
                                                                  @"sha512": [NSNumber numberWithInt:kCCHmacAlgSHA512]};
    
    return [supportedAlgorithms valueForKey:[algorithm lowercaseString]];
}

static NSNumber* parseDigits(const NSString *digits) {
    if (digits.length == 0) {
        return [NSNumber numberWithInt:6];
    }
    int val = [digits intValue];
    if (val != 6 && val != 8) {
        return nil;
    }
    return [NSNumber numberWithInt:val];
}

static NSNumber* parseCounter(const NSString *counter) {
    if (counter.length == 0 || !isNumeric(counter)) {
        return nil;
    }
    
    return [NSNumber numberWithInteger:[counter integerValue]];
}

static NSNumber* parsePeriod(const NSString *period) {
    if (period.length == 0) {
        return [NSNumber numberWithInt:30];
    }
    
    if (!isNumeric(period)) {
        return nil;
    }
    
    uint32_t intPeriod = [period intValue];
    if (intPeriod == 0) {
        return nil;
    }
    
    return [NSNumber numberWithInt:intPeriod];
}

static BOOL isNumeric (const NSString *string) {
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [string rangeOfCharacterFromSet:notDigits].location == NSNotFound;
}

static NSString* parseIssuer(NSString* issuerPrefix, NSString* issuerParameter, NSString* accountName) {
    if (issuerPrefix.length > 0) {
        return issuerPrefix;
    }
    
    if (issuerParameter.length > 0) {
        return issuerParameter;
    }
    
    return accountName;
}

static BOOL isValidBackgroundColor(NSString *color) {
    if (color.length == 0) {
        return YES;
    }
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9a-fA-F]{6}$" options:0 error:nil];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:color options:0 range:NSMakeRange(0, [color length])];
    
    if (numberOfMatches == 1) {
        return YES;
    };
    return NO;
}

@end