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

@class FRAIdentity;
@class FRAIdentityDatabase;
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
 * Mechansim. Will not be responsible for database persistence.
 */
@interface FRAMechanismFactory : NSObject

/*!
 * Property exposed for setter injection via Typhoon.
 */
@property (nonatomic, strong) FRAIdentityDatabase* database;

/*!
 * Given a URL, convert this into a FRAMechanism, complete with associated Identity.
 *
 * @param non nil URL to parse.
 * @return non nil FRAMechanism initialsed with the values present in the URL.
 */
- (FRAMechanism*) parseFromURL: (NSURL*) url;

/*!
 * Convenience function which will call parseFromURL.
 */
- (FRAMechanism*) parseFromString: (NSString*) string;

@end