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



#import "FRAModelObject.h"

@class FRAIdentity;
@class FRAIdentityDatabase;
@class FRANotification;

/*!
 * A mechanism used for authentication within the Authenticator Application.
 *
 * Encapsulates the related settings, as well as an owning Identity.
 */
@interface FRAMechanism : FRAModelObject {
    @protected
    NSInteger _version;
}

/*!
 * The parent Identity object which this mechanism belongs to.
 */
// NB. FRAIdentity and FRAMechanism hold a strong reference to each other - Necessary as FRAMechanismFactory
// returns FRAMechanism which may reference a new FRAIdentity.
@property (nonatomic) FRAIdentity *parent;

/*!
 * The version number of this mechanism.
 */
@property (nonatomic, readonly) NSInteger version;

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
 * @param identityModel The identity model which contains the list of identities.
 * @return The initialized mechanism or nil if initialization failed.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel;

#pragma mark -
#pragma mark Notification Functions

/*!
 * When a new notification is received by the App, it will be appended to
 * the owning Mechanism using this method.
 *
 * @param notification The notification to add to this Mechanism.
 * @param error If there was an error, this value will be populated.
 * @return BOOL NO if there was an error adding the Notification, in which case the error value will be populated.
 */
- (BOOL)addNotification:(FRANotification *)notification error:(NSError *__autoreleasing*)error;

/*!
 * Once a Notification has been marked as deleted, it will be removed from 
 * the Mechanism by this method.
 *
 * @param notification The notification to remove from the Mechanism.
 * @param error If there was an error, this value will be populated.
 * @return BOOL NO if there was an error adding the Notification, in which case the error value will be populated.
 */
- (BOOL)removeNotification:(FRANotification *)notification error:(NSError *__autoreleasing*)error;

/*!
 * Count of notifications that have not yet been dealt with.
 *
 * @return The number of pending notifications.
 */
- (NSInteger)pendingNotificationsCount;

/*!
 * Gets the notification identified uniquely by the provided messageID.
 * @param messageId The message id of the notification to get.
 * @return The notification with the specified messageId or nil if no match is found.
 */
- (FRANotification *)notificationWithMessageId:(NSString *)messageId;

/*!
 * Return the mechanism type (i.e. totp, hotp or push).
 */
+ (NSString *)mechanismType;

@end
