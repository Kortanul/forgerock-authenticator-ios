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

#include <CommonCrypto/CommonHMAC.h>
#include <sys/time.h>
#include "base32.h"

#import <sys/time.h>

/*!
 * Methods for dealing with keyed-hash message authentication codes (HMAC).
 */
@interface FRAOathCode : NSObject

/*!
 * Create a keyed-hash message authentication code (HMAC).
 *
 * @param algorithm The cryptographic function to use in the calculation of the HMAC.
 * @param codeLength The length of the code.
 * @param key The secret key.
 * @param counter The counter to hash.
 *
 * @return The keyed-hash message authentication code (HMAC).
 */
+ (NSString *)hmac:(CCHmacAlgorithm)algorithm codeLength:(uint8_t)codeLength key:(NSData *)key counter:(uint64_t) counter;

/*!
 * String representation of an HMAC algorithm.
 *
 * @param algorithm The HMAC algorithm to convert to a string.
 *
 * @return The string representation of the HMAC algorithm.
 */
+ (NSString *)asString:(CCHmacAlgorithm)algorithm;

/*!
 * Convert string to HMAC algorithm constant.
 *
 * @param string The string to convert back to the HMAC algorithm constant.
 *
 * @return The HMAC algorithm constant.
 */
+ (CCHmacAlgorithm)fromString:(NSString *) string;

/*!
 * Returns the number of bytes used by a specific HMAC algorithm.
 *
 * @param algorithm The HMAC algorithm.
 *
 * @return The number of bytes used by the algorithm.
 */
+ (int)getDigestLength:(CCHmacAlgorithm) algorithm;

@end
