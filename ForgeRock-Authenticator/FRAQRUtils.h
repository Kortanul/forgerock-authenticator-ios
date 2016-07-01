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
 * Replaces characters for url decoding.
 *
 * @param content The original string.
 * @return The string with replaced characters.
 */
+ (NSString *)replaceCharactersForURLDecoding:(NSString *)content;

/*!
 * Decodes from Base64 url encoded string.
 *
 * @param content The original string to decode.
 * @return The decoded string.
 */
+ (NSData *)decodeURL:(NSString *)content;

/*!
 * Decodes a Base64 encoded string.
 *
 * @param base64String The original Base64 string to decode.
 * @return The decoded string.
 */
+ (NSData *)decodeBase64:(NSString *)base64String;

/*!
 * Decodes an encoded string.
 *
 * @param content The original string to decode.
 * @return The decode string.
 */
+ (NSString *)decode:(NSString*)content;

/*!
 * Pads a string with '=' to have length multiple of 4 (for Base64 decoding).
 *
 * @param content The original string to pad.
 * @return The padded string.
 */
+ (NSString *)pad:(NSString*)content;


/*!
 * Checks if the given string is a valid Base64 string.
 *
 * @param content The original string to check.
 * @return YES if the string is a valid Base64 string, otherwise NO.
 */
+ (BOOL)isBase64:(NSString *)content;

@end