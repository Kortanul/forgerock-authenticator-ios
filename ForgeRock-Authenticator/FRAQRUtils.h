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

/*!
 * Utility class for assisting in the reading of QR code uri strings.
 */
@interface FRAQRUtils : NSObject

/*!
 * replace characters for url decoding
 */
+ (NSString *) replaceCharactersForURLDecoding:(NSString *)content;

/*!
 * decode a url from base 64 url encoded string
 */
+ (NSData *) decodeURL:(NSString *) content;

/*!
 * decode a base 64 encoded string
 */
+ (NSData *) decodeBase64:(NSString *) base64String;

/*!
 * decode an encoded string
 */
+ (NSString *) decode:(NSString*) str;

/*!
 * Pad string with '=' to have length multiple of 4 (for base 64 decoding)
 */
+ (NSString *) pad:(NSString*) str;


@end