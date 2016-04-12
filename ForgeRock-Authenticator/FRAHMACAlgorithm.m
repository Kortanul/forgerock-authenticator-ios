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


#import "FRAHMACAlgorithm.h"

@implementation FRAHMACAlgorithm

+ (NSString *)asString:(CCHmacAlgorithm)algorithm {
    if (algorithm == kCCHmacAlgMD5) {
        return @"md5";
    }
    if (algorithm == kCCHmacAlgSHA256) {
        return @"sha256";
    }
    if (algorithm == kCCHmacAlgSHA512) {
        return @"sha512";
    }
    return @"sha1";
}

+ (CCHmacAlgorithm)fromString:(NSString *) string {
    if ([string  isEqual: @"md5"]) {
        return kCCHmacAlgMD5;
    }
    if ([string  isEqual: @"sha256"]) {
        return kCCHmacAlgSHA256;
    }
    if ([string  isEqual: @"sha512"]) {
        return kCCHmacAlgSHA512;
    }
    return kCCHmacAlgSHA1;
}

+ (int)getDigestLength:(CCHmacAlgorithm) algorithm {
    switch (algorithm) {
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

@end