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
@class FRAIdentityModel;
@class FRAMechanism;
@class FRANotification;
@class FRASqlDatabase;

/*!
 * Delegate for FRAIdentityDatabase SQL operations.
 *
 * Allows non-SQL operations of FRAIdentityDatabase to be unit tested.
 */
@interface FRAIdentityDatabaseSQLiteOperations : NSObject

#pragma mark -
#pragma Life cycle Functions

- (instancetype)initWithDatabase:(FRASqlDatabase *)database;

#pragma mark -
#pragma mark Identity Functions

/*!
 * Save the identity to the database.
 * @param identity The identity to save.
 */
- (BOOL)insertIdentity:(FRAIdentity *)identity error:(NSError *__autoreleasing *)error;

/*!
 * Remove the identity from the database.
 * @param identity The identity to remove.
 */
- (BOOL)deleteIdentity:(FRAIdentity *)identity error:(NSError *__autoreleasing *)error;

#pragma mark -
#pragma mark Mechanism Functions

/*!
 * Save a new mechanism to the database.
 * @param mechanism The mechanism to save.
 */
- (BOOL)insertMechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing *)error;

/*!
 * Remove the mechanism from the database.
 * @param mechanism The mechanism to remove.
 */
- (BOOL)deleteMechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing *)error;

/*!
 * Save changes to an existing mechanism to the database.
 * @param mechanism The mechanism to save.
 */
- (BOOL)updateMechanism:(FRAMechanism *)mechanism error:(NSError *__autoreleasing *)error;

#pragma mark -
#pragma mark Notification Functions

/*!
 * Save a new notification to the database.
 * @param notification The notification to save.
 */
- (BOOL)insertNotification:(FRANotification *)notification error:(NSError *__autoreleasing *)error;

/*!
 * Remove the notification from the database.
 * @param notification The notification to remove.
 */
- (BOOL)deleteNotification:(FRANotification *)notification error:(NSError *__autoreleasing *)error;

/*!
 * Save changes to an existing notification to the database.
 * @param notification The notification to save.
 */
- (BOOL)updateNotification:(FRANotification *)notification error:(NSError *__autoreleasing *)error;

@end
