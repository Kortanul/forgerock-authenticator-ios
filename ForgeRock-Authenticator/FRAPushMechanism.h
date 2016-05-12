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

@property (nonatomic, readonly) NSString* secret;
@property (nonatomic, readonly) NSString* authEndpoint;
@property (nonatomic, readonly) NSString* issuer;
@property (nonatomic, readonly) NSString* image;
@property (nonatomic, readonly) NSString* bgColour;

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
 * Init Push Mechanism
 *
 * @param database the database to store this object it
 * @param authEndpoint the authentirsation enpoint uri to use when authenticating using this mechanism
 * @param secret the secret key for the authentication exchange
 * @param image the image ti display for this mechanism
 * @param bgColour the backjground colour for displaying this mechanism
 * @param issuer the issuer name to display for this mechanism
 *
 * @return The initialized mechanism or nil if initialization failed.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database authEndpoint:(NSString *)a secret:s image:(NSString *)image bgColour:(NSString *)b issuer:(NSString *)issuer;

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
+ (instancetype)pushMechanismWithDatabase:(FRAIdentityDatabase *)database authEndpoint:(NSString *)a secret:s image:(NSString *)image bgColour:(NSString *)b issuer:(NSString *)issuer;

@end
