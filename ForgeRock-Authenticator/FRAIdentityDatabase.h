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

#import <Foundation/Foundation.h>
@class FRAIdentity;
@class FRAIdentityDatabase;
@class FRAIdentityDatabaseSQLiteOperations;
@class FRAIdentityModel;
@class FRAMechanism;
@class FRANotification;


/*! Identifier for NSNotificationCenter event broadcast by FRAIdentityDatase when state change occurs. */
extern NSString * const FRAIdentityDatabaseChangedNotification;

/*! Key identifying added objects in FRAIdentityDatabaseChangedNotification userInfo dictionary. */
extern NSString * const FRAIdentityDatabaseChangedNotificationAddedItems;

/*! Key identifying removed objects in FRAIdentityDatabaseChangedNotification userInfo dictionary. */
extern NSString * const FRAIdentityDatabaseChangedNotificationRemovedItems;

/*! Key identifying updated objects in FRAIdentityDatabaseChangedNotification userInfo dictionary. */
extern NSString * const FRAIdentityDatabaseChangedNotificationUpdatedItems;

/*! Initial storageId value for model objects before they are persisted to the database. */
extern NSInteger const FRANotStored;


/*!
 * Data Access Object which encapsulates the underlying storage
 * mechanism and provides a simplified interface to the caller.
 * 
 * Responsible for manipulating Identity, Mechanism and Notification
 * objects in the database.
 */
@interface FRAIdentityDatabase : NSObject

@property (strong, nonatomic, readonly) FRAIdentityDatabaseSQLiteOperations *sqlOperations;

#pragma mark -
#pragma mark Lifecycle

- (instancetype)initWithSqlOperations:(FRAIdentityDatabaseSQLiteOperations *)sqlOperations;

#pragma mark -
#pragma mark Identity Functions

/*!
 * Save the identity to the database.
 * @param identity The identity to save.
 */
- (void)insertIdentity:(FRAIdentity *)identity;

/*!
 * Remove the identity from the database.
 * @param identity The identity to remove.
 */
- (void)deleteIdentity:(FRAIdentity *)identity;

#pragma mark -
#pragma mark Mechanism Functions

/*!
 * Save a new mechanism to the database.
 * @param mechanism The mechanism to save.
 */
- (void)insertMechanism:(FRAMechanism *)mechanism;

/*!
 * Remove the mechanism from the database.
 * @param mechanism The mechanism to remove.
 */
- (void)deleteMechanism:(FRAMechanism *)mechanism;

/*!
 * Save changes to an existing mechanism to the database.
 * @param mechanism The mechanism to save.
 */
- (void)updateMechanism:(FRAMechanism *)mechanism;

#pragma mark -
#pragma mark Notification Functions

/*!
 * Save a new notification to the database.
 * @param notification The notification to save.
 */
- (void)insertNotification:(FRANotification *)notification;

/*!
 * Remove the notification from the database.
 * @param notification The notification to remove.
 */
- (void)deleteNotification:(FRANotification *)notification;

/*!
 * Save changes to an existing notification to the database.
 * @param notification The notification to save.
 */
- (void)updateNotification:(FRANotification *)notification;

@end
