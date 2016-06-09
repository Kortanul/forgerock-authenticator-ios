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

#import "FRAMechanism.h"

@interface FRAHotpOathMechanism : FRAMechanism

#pragma mark -
#pragma mark Properties

/*!
 * The length of the OATH code generated by the mechanism. Always 6 or 8; defaults to 6.
 */
@property (nonatomic, readonly) NSUInteger codeLength;
/*!
 * The current login code for the OATH mechanism.
 */
@property (nonatomic, readonly) NSString *code;
/*!
 * The secret key bytes used by the OATH mechanism.
 */
@property (nonatomic, readonly) NSData *secretKey;
/*!
 * The algorithm used for generating the next hash code.
 */
@property (nonatomic, readonly) CCHmacAlgorithm algorithm;
/*!
 * The HMAC counter which is used to generate the next hash code.
 */
@property (nonatomic, readonly) u_int64_t counter;

#pragma mark -
#pragma mark Lifecyle

/*!
 * Initialize an HOTP OATH mechanism.
 *
 * @param database The database to which the mechanism can be persisted.
 * @param identityModel The identity model which contains the list of identities.
 * @param secretKey The secret key bytes used to generate the HMAC.
 * @param algorithm The HMAC algorithm to use. Currently only MD5, SHA256, SHA512 and SHA1 are supported.
 * @param codeLenght The length of the code.
 * @param counter HOTP hash counter.
 *
 * @return The initialized mechanism or nil if initialization failed.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel secretKey:(NSData *)secretKey HMACAlgorithm:(CCHmacAlgorithm)algorithm codeLength:(NSUInteger)codeLenght counter:(u_int64_t)counter;

/*!
 * Allocate and initialize an HOTP OATH mechanism.
 *
 * @param database The database to which the mechanism can be persisted.
 * @param identityModel The identity model which contains the list of identities.
 * @param secretKey The secret key bytes used to generate the HMAC.
 * @param algorithm The HMAC algorithm to use. Currently only MD5, SHA256, SHA512 and SHA1 are supported.
 * @param codeLength The length of the code.
 * @param counter HOTP hash counter.
 *
 * @return The initialized mechanism or nil if initialization failed.
 */
+ (instancetype)mechanismWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel secretKey:(NSData *)secretKey HMACAlgorithm:(CCHmacAlgorithm)algorithm codeLength:(NSUInteger)codeLength counter:(u_int64_t)counter;

#pragma mark -
#pragma mark Instance Methods

/*!
 * Generates the next code for this OATH mechanism.
 */
- (void)generateNextCode:(NSError *__autoreleasing*)error;

@end