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

#import "FRAOathCode.h"
#import "FRATotpOathMechanism.h"

static uint64_t currentTimeInMilli() {
    struct timeval tv;
    
    if (gettimeofday(&tv, NULL) != 0) {
        return 0;
    }
    
    return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

@implementation FRATotpOathMechanism {
    uint64_t startTime;
    uint64_t endTime;
}

#pragma mark -
#pragma mark Lifecyle

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel secretKey:(NSData *)secretKey HMACAlgorithm:(CCHmacAlgorithm)algorithm codeLength:(NSUInteger)codeLength period:(u_int32_t)period {
    self = [super initWithDatabase:database identityModel:identityModel];
    if (self) {
        _secretKey = secretKey;
        _algorithm = algorithm;
        _codeLength = codeLength;
        _period = period;
        _version = 1;
    }
    return self;
}

+ (instancetype)mechanismWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel secretKey:(NSData *)secretKey HMACAlgorithm:(CCHmacAlgorithm)algorithm codeLength:(NSUInteger)codeLength period:(u_int32_t)period {
    return [[FRATotpOathMechanism alloc] initWithDatabase:database identityModel:identityModel secretKey:secretKey HMACAlgorithm:algorithm codeLength:codeLength period:period];
}

#pragma mark -
#pragma mark Instance Methods

- (void)generateNextCode:(NSError *__autoreleasing *)error {
    time_t now = time(NULL);
    if (now == (time_t) -1) {
        now = 0;
    }
    uint64_t startTimeInSeconds = (now / self.period * self.period);
    startTime = startTimeInSeconds * 1000;
    endTime = (startTimeInSeconds + self.period) * 1000;
    _code = [FRAOathCode hmac:self.algorithm codeLength:self.codeLength key:self.secretKey counter:now/self.period];
}

- (float)progress {
    uint64_t now = currentTimeInMilli();

    if (now < startTime) {
        return 0.0;
    }
    if (now < endTime) {
        float totalTime = (float) (endTime - startTime);
        return (now - startTime) / totalTime;
    }
    return 1.0;
}

- (BOOL)hasExpired {
    return [self progress] == 1.0;
}

+ (NSString *)mechanismType {
    return @"totp";
}

@end