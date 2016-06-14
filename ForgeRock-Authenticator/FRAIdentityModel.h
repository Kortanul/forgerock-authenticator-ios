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

@class FRAFMDatabaseConnectionHelper;
@class FRAIdentity;
@class FRAIdentityDatabase;
@class FRAMechanism;
@class FRANotification;

/*!
 * Root of the Authenticator data model containing a listing of identities and methods for querying them.
 */
@interface FRAIdentityModel : NSObject

#pragma mark -
#pragma mark Lifecycle

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database sqlDatabase:(FRAFMDatabaseConnectionHelper *) sql;

#pragma mark -
#pragma mark Identity Functions

/*!
 * Gets all of the identities which are stored.
 * @return The list of identities.
 */
- (NSArray *)identities;

/*!
 * Gets the identity uniquely identified by the specified issuer and accountName.
 * @param issuer The issuer of the identity.
 * @param accountName The name of the identity.
 * @return The identity that was stored.
 */
- (FRAIdentity *)identityWithIssuer:(NSString *)issuer accountName:(NSString *)accountName;

/*!
 * Add the identity to the database.
 * @param identity The identity to add.
 * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 * @return YES if the identity is added to the identity model, otherwise NO.
 */
- (BOOL)addIdentity:(FRAIdentity *)identity error:(NSError *__autoreleasing *)error;

/*!
 * Remove the provided Identity from the model.
 * @param identity The identity to remove.
 * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 * @return YES if the identity is removed from the identity model, otherwise NO.
 */
- (BOOL)removeIdentity:(FRAIdentity *)identity error:(NSError *__autoreleasing *)error;

#pragma mark -
#pragma mark Mechanism Functions

/*!
 * Gets the mechanism identified uniquely by the provided ID.
 * @param uid The storage id of the mechanism to get.
 * @return The mechanism with the specified storage ID.
 */
- (FRAMechanism *)mechanismWithId:(NSString *)uid;

#pragma mark -
#pragma mark Notification Functions

/*!
 * Count of notifications that have not yet been dealt with.
 *
 * @return The number of pending notifications.
 */
- (NSInteger)pendingNotificationsCount;

@end
