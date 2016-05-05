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

#import "FRAModelObject.h"

@class FRAIdentity;
@class FRAIdentityDatabase;
@class FRANotification;

/*!
 * A mechanism used for authentication within the Authenticator Application.
 *
 * Encapsulates the related settings, as well as an owning Identity.
 */
@interface FRAMechanism : FRAModelObject

/*!
 * The parent Identity object which this mechanism belongs to.
 */
// NB. FRAIdentity and FRAMechanism hold a strong reference to each other - Necessary as FRAMechanismFactory
// returns FRAMechanism which may reference a new FRAIdentity.
@property (nonatomic) FRAIdentity *parent;

/*!
 * A list of the current Notficiations that are assigned to this Mechanism.
 */
@property (getter=notifications, nonatomic, readonly) NSArray<FRANotification *> *notifications;

#pragma mark -
#pragma mark Lifecyle

/*!
 * Init method.
 *
 * @param database The database to which this mechanism can be persisted.
 * @return The initialized mechanism or nil if initialization failed.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database;

#pragma mark -
#pragma mark Notification Functions

/*!
 * When a new notification is received by the App, it will be appended to
 * the owning Mechanism using this method.
 *
 * @param notification The notification to add to this Mechanism.
 */
- (void)addNotification:(FRANotification *)notification;

/*!
 * Once a Notficiation has been marked as deleted, it will be removed from 
 * the Mechanism by this method.
 *
 * @param notification The notification to remove from the Mechanism.
 */
- (void)removeNotification:(FRANotification *)notification;

/*!
 * Count of notifications that have not yet been dealt with.
 *
 * @return The number of pending notifications.
 */
- (NSInteger)pendingNotificationsCount;

@end
