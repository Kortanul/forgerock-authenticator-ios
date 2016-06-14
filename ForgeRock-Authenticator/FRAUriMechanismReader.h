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


#import "FRAMechanismFactory.h"

@class FRAIdentity;
@class FRAIdentityModel;
@class FRAMechanism;

/*!
 * This Authenticator Application makes use of the existing OATH
 * URL scheme for encoding Identity and Mechanism information.
 *
 * This is defined in detail here:
 * https://github.com/google/google-authenticator/wiki/Key-Uri-Format
 *
 * This factory will also be able to parse a similar URL scheme
 * Push Authentication when it is supported by this Application.
 *
 * Note: Only responsible for generating the instances of Identity and
 * Mechanism. Will not be responsible for database persistence.
 */
@interface FRAUriMechanismReader : NSObject

#pragma mark -
#pragma mark Lifecycle

/*!
 * Init method.
 *
 * @param database The database to which this object can be persisted.
 * @return The initialized object or nil if initialization failed.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel;

/*!
 * Adds a mechanism factory to this Mechanism Readert.  
 * The added mechanism Factory adds the capability to decode a new type of message.
 *
 * @param factory The FRAMechanismFactory to add to this reader.
 */
- (void)addMechanismFactory:(id<FRAMechanismFactory>)factory;

#pragma mark -
#pragma mark URL Reading Functions

/*!
 * Given a URL, convert this into a FRAMechanism, complete with associated Identity.
 *
 * @param url The URL to parse, non-nil.
 * @param handler The block to invoke when asynchronous operation is completed.
 * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 * @return non nil FRAMechanism initialsed with the values present in the URL.
 */
- (FRAMechanism*)parseFromURL:(NSURL*)url handler:(void(^)(BOOL, NSError *))handler error:(NSError *__autoreleasing *)error;

/*!
 * Convenience function which will call parseFromURL.
 * 
 * @param string the String uri to parse a mechanism from.
 * @param handler The block to invoke when asynchronous operation is completed.
 * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 * @return the FRAMechanism object extracted from the string.
 */
- (FRAMechanism*)parseFromString:(NSString*)string handler:(void(^)(BOOL, NSError *))handler error:(NSError *__autoreleasing *)error;

@end