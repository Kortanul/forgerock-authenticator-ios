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
#import "FRAOathCode.h"

#include <CommonCrypto/CommonHMAC.h>
#include <sys/time.h>
#include "base32.h"

@implementation FRAOathMechanism {
    CCHmacAlgorithm algo;
    NSData*   key;
    uint64_t counter;
    uint32_t period;
}

- (instancetype) initWithType:(NSString*)type usingSecretKey:(NSData*)secretKey andHMACAlgorithm:(CCHmacAlgorithm)algorithm withKeyLength:(NSUInteger)digits andEitherPeriod:(NSUInteger)timePeriod orCounter:(NSUInteger)hmacCounter {
    
    self = [super init];
    if (self) {
        _type = type;
        key = secretKey;
        algo = algorithm;
        _digits = digits;
        period = timePeriod;
        counter = hmacCounter;
        _version = 1;
    }
    return self;
}

- (void)generateNextCode {
    time_t now = time(NULL);
    if (now == (time_t) -1) {
        now = 0;
    }
    if ([_type isEqualToString:@"hotp"]) {
        NSString* code = getHOTP(algo, _digits, key, counter++);
        uint64_t startTime = now;
        uint64_t endTime = startTime + period;
        _code = [[FRAOathCode alloc] initWithValue:code startTime:startTime endTime:endTime];
    } if ([_type isEqualToString:@"totp"]) {
        NSString* code = getHOTP(algo, _digits, key, now / period);
        uint64_t startTime = now / period * period;
        uint64_t endTime = startTime + period;
        _code = [[FRAOathCode alloc] initWithValue:code startTime:startTime endTime:endTime];
    }
}

#pragma mark --
#pragma mark FRAOathMechanism (static private)

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

@end
