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
@class FRAMechanism;
@class FRANotification;
@class FRAOathMechanism;

/*!
 * Listens to a database for the data to change.
 */
@protocol FRADatabaseListener <NSObject>

/*!
 * Called when any write operation takes place.
 */
- (void)onUpdate;

@end


/*!
 * Data Access Object which encapsulates the underlying storage
 * mechanism and provides a simplified interface to the caller.
 * 
 * Responsible for manipulating Identity, Mechanism and Notification
 * objects in the database.
 */
@interface FRAIdentityDatabase : NSObject

/*!
 * Gets all of the identities which are stored.
 * @return The list of identities.
 */
- (NSArray*)identities;

/*!
 * Gets the identity identified uniquely by the provided ID.
 * @param uid The storage id of the identity to get.
 * @return The identity with the specified storage ID.
 */
- (FRAIdentity*)identityWithId:(NSInteger)uid;

/*!
 * Gets the mechanism identified uniquely by the provided ID.
 * @param uid The storage id of the mechanism to get.
 * @return The mechanism with the specified storage ID.
 */
- (FRAOathMechanism*)mechanismWithId:(NSInteger)uid;

/*!
 * Gets the identity uniquely identified by the specified issuer and accountName.
 * @param issuer The issuer of the identity.
 * @param accountName The name of the identity.
 * @return The identity that was stored.
 */
- (FRAIdentity*)identityWithIssuer:(NSString*)issuer accountName:(NSString*)accountName;

/*!
 * Add the identity to the database.
 * @param id The identity to add.
 */
- (void)addIdentity:(FRAIdentity*)identity;

/*!
 * Delete the identity uniquely identified by the specified storage ID.
 * @param uid The storage ID of the identity to delete.
 */
- (void)removeIdentityWithId:(NSInteger)uid;

/*!
 * Remove the provided Identity from the model.
 */
- (void)removeIdentity:(FRAIdentity*) identity;

/*!
 * Add the mechanism to the database. If the owning identity is not yet stored, store that as well.
 * @param mechanism The mechanism to store.
 */
- (void)addMechanism:(FRAMechanism*)mechanism;

/*!
 * Update the mechanism in the database. Does not create it if it does not exist.
 * @param mechanism The mechanism to update.
 */
- (void)updateMechanism:(FRAMechanism*)mechanism;

/*!
 * Remove the mechanism in the database.
 * @param mechanism The mechanism to update.
 */
- (void)removeMechanism:(FRAMechanism*)mechanism;

/*!
 * Remove the notification from the database.
 */
- (void) removeNotification:(FRANotification*) notification;

/*!
 * Add a listener to this connection.
 * @param listener The listener to add.
 */
- (void)addListener:(id<FRADatabaseListener>)listener;

@end
