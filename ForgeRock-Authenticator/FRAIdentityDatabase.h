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
 * Data Access Object which can store and load both Identities and Mechanisms.
 * Encapsulates the specific storage mechanism.
 */
@interface FRAIdentityDatabase : NSObject

/*!
 * Accessor for singleton.
 *
 * This is a temporary solution that should be fixed when setting up the skeleton screens and segues;
 * the correct solution for making the database accessible to all objects that need it is dependency injection.
 */
+ (FRAIdentityDatabase*)singleton;

/*!
 * Gets all of the identities which are stored.
 * @return The list of identities.
 */
- (NSArray*)identities;

/*!
 * Gets the mechanism identified uniquely by the provided ID.
 * @param uid The storage id of the mechanism to get.
 * @return The mechanism with the specified storage ID.
 */
- (FRAOathMechanism*)mechanismWithId:(NSInteger)uid;

/*!
 * Get the mechanisms associated with an owning identity.
 * @param owner The account to which the returned mechanisms were registered.
 * @return The mechanisms registered to the specified identity.
 */
- (NSArray*)mechanismsWithOwner:(FRAIdentity*)owner;

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
 * Add the mechanism to the database. If the owning identity is not yet stored, store that as well.
 * @param mechanism The mechanism to store.
 */
- (void)addMechanism:(FRAOathMechanism*)mechanism;

/*!
 * Update the mechanism in the database. Does not create it if it does not exist.
 * @param mechanism The mechanism to update.
 */
- (void)updateMechanism:(FRAOathMechanism*)mechanism;

/*!
 * Delete the mechanism uniquely identified by the specified storage ID.
 * @param uid The storage ID of the mechanism to delete.
 */
- (void)removeMechanismWithId:(NSInteger)uid;

/*!
 * Add a listener to this connection.
 * @param listener The listener to add.
 */
- (void)addListener:(id<FRADatabaseListener>)listener;

@end
