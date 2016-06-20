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

#include <CommonCrypto/CommonHMAC.h>

#import "FRAHotpOathMechanism.h"
#import "FRAIdentityDatabase.h"
#import "FRAModelObjectProtected.h"
#import "FRAOathCode.h"

@implementation FRAHotpOathMechanism

#pragma mark -
#pragma mark Lifecyle

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel secretKey:(NSData *)secretKey HMACAlgorithm:(CCHmacAlgorithm)algorithm codeLength:(NSUInteger)codeLenght counter:(u_int64_t)counter {
    self = [super initWithDatabase:database identityModel:identityModel];
    if (self) {
        _secretKey = secretKey;
        _algorithm = algorithm;
        _codeLength = codeLenght;
        _counter = counter;
        _version = 1;
    }
    return self;
}

+ (instancetype)mechanismWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel secretKey:(NSData *)secretKey HMACAlgorithm:(CCHmacAlgorithm)algorithm codeLength:(NSUInteger)codeLength counter:(u_int64_t)counter {
    return [[FRAHotpOathMechanism alloc] initWithDatabase:database identityModel:identityModel secretKey:secretKey HMACAlgorithm:algorithm codeLength:codeLength counter:counter];
}

#pragma mark -
#pragma mark Instance Methods

- (BOOL)generateNextCode:(NSError *__autoreleasing*)error {
    NSString *previousCode = _code;
    _code = [FRAOathCode hmac:self.algorithm codeLength:self.codeLength key:self.secretKey counter:_counter++];
    if ([self.database updateMechanism:self error:error]) {
        return YES;
    }
    
    _code = previousCode;
    return NO;
}

+ (NSString *)mechanismType {
    return @"hotp";
}

@end