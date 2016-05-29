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
#import "FRAMechanism.h"

/*!
 * An authentication mechanism capable of authenticating by responding to a push notification.
 */
@interface FRAPushMechanism : FRAMechanism

/*!
 * The version number of this mechanism.
 */
@property (nonatomic, readonly) NSInteger version;

/*!
 * Secret key for Push Notifications
 */
@property (nonatomic, readonly) NSString *secret;

/*!
 * Authentication Endpoint to contact for Push Notifications
 */
@property (nonatomic, readonly) NSString *authEndpoint;

/*!
 * The type of this mechanism. E.g. push
 */
@property (nonatomic, readonly) NSString* type;

/*!
 * The Device ID that this device is registered under.
 */
@property (nonatomic, readonly) NSString* mechanismUID;

#pragma mark -
#pragma mark Lifecyle

/*!
 * Init Push Mechanism.
 *
 * @param database The database to which this mechanism can be persisted.
 *
 * @return The initialized mechanism or nil if initialization failed.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database;

/*!
 * Create an instance of PushMechanism
 *
 * @param database Required to allow mechnaism to persist changes
 * @param authEndPoint The authentication endpoint URI used for signalling to the server
 * @param secret Shared secret key required for authentication
 * @param version the version of the database object
 * @param mechanismIdentifier uid for the mechanism
 *
 * @return The initialized mechanism or nil if initialization failed.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database authEndpoint:(NSString *)authEndPoint secret:(NSString *)secret version:(NSInteger)version mechanismIdentifier:(NSString *)mechanismIdentifier;

/*!
 * Create an instance of PushMechanism
 *
 * @param database Required to allow mechnaism to persist changes
 * @param authEndPoint The authentication endpoint URI used for signalling to the server
 * @param secret Shared secret key required for authentication
 *
 * @return The initialized mechanism or nil if initialization failed.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database authEndpoint:(NSString *)authEndPoint secret:(NSString *)secret;

/*!
 * Allocate and init Push Mechanism.
 *
 * @param database The database to which this mechanism can be persisted.
 *
 * @return The initialized mechanism or nil if initialization failed.
 */
+ (instancetype)pushMechanismWithDatabase:(FRAIdentityDatabase *)database;

/*!
 * Allocate and init Push Mechanism.
 *
 * @param database The database to which this mechanism can be persisted.
 *
 * @return The initialized mechanism or nil if initialization failed.
 */
+ (instancetype)pushMechanismWithDatabase:(FRAIdentityDatabase *)database authEndpoint:(NSString *)authEndPoint secret:(NSString *)secret;

/*!
 * Allocate and init Push Mechanism with version information included.
 *
 * @param database The database to which this mechanism can be persisted.
 *
 * @return The initialized mechanism or nil if initialization failed.
 */
+ (instancetype)pushMechanismWithDatabase:(FRAIdentityDatabase *)database authEndpoint:(NSString *)authEndPoint secret:(NSString *)secret version:(NSInteger)version mechanismIdentifier:(NSString *)mechanismIdentifier;

@end
