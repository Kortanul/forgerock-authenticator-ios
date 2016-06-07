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
 * Mechanism Secret Key
 */
extern NSString *const OATH_MECHANISM_SECRET;

/*!
 * Mechanism Hashing Algorithm
 */
extern NSString *const OATH_MECHANISM_ALGORITHM;

/*!
 * Mechanism Key length
 */
extern NSString *const OATH_MECHANISM_DIGITS;

/*!
 * Mechanism TOTP Period
 */
extern NSString *const OATH_MECHANISM_PERIOD;

/*!
 * Mechanism HOTP Counter
 */
extern NSString *const OATH_MECHANISM_COUNTER;

/*!
 * Storage key for Push Notification protocol version
 */
extern NSString *const PUSH_MECHANISM_VERSION;

/*!
 * Storage key for Push Notification secret key
 */
extern NSString *const PUSH_MECHANISM_SECRET;

/*!
 * Storage key for Push Notification authentication endpoint
 */
extern NSString *const PUSH_MECHANISM_AUTH_END_POINT;

/*!
 * Notification Message ID
 */
extern NSString *const NOTIFICATION_MESSAGE_ID;

/*!
 * Notification Push Challenge
 */
extern NSString *const NOTIFICATION_PUSH_CHALLENGE;

/*!
 * Notification Time To Live
 */
extern NSString *const NOTIFICATION_TIME_TO_LIVE;

/*!
 * Notification Load Balancer cookie
 */
extern NSString * const NOTIFICATION_LOAD_BALANCER_COOKIE;

/*!
 * A collection of useful data storage functions to simplify persistence
 * of data structures to JSON and back again.
 */
@interface FRASerialization : NSObject

/*!
 * Given a Dictionary of values, serialised them into JSON.
 *
 * @param dictionary Dictionary of values to map, maybe nil
 * @param jsonString Output string to contain the JSON
 * @param error Error reference if there was a problem during the serialisation
 *
 * @return NO if there was an error, otherwise YES to indicate no error occured
 */
+ (BOOL)serializeMap:(NSDictionary *)dictionary intoString:(NSString *__autoreleasing *)jsonString error:(NSError *__autoreleasing *)error;

/*!
 * Given a JSON string, deserialise it into a Dictionary.
 *
 * @param dictionaryJson String containing JSON to deserialise, maybe nil
 * @param dictionary Output value to store Dictionary into
 * @param error Error reference if there was a problem during the serialisation
 *
 * @return NO if there was an error, otherwise YES to indicate no error occured
 */
+ (BOOL)deserializeJSON:(NSString *)dictionaryJson intoDictionary:(NSDictionary *__autoreleasing *)dictionary error:(NSError *__autoreleasing *)error;

/*!
 * Given a byte array, serialise it to text using Base64.
 *
 * @param data Byte array of data to serialise, may be nil.
 * @return nil if the input was nil, otherwise non nil string containing the data.
 */
+ (NSString *)serializeBytes:(NSData *)data;

/*!
 * Given a Base64 encoded string, deserialise it to a byte array.
 *
 * @param data Encoded data to deserialise.
 * @return nil if the input was nil, otherwise non nil byte array.
 */
+ (NSData *)deserializeBytes:(NSString *)data;

// TODO think about these functions.
+ (id)nonNilDate:(NSDate *)date;
+ (id)nonNilString:(NSString *)string;
+ (NSString *)nullToEmpty:(NSString *)string;

@end