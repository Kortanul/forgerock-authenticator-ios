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

@class FRAIdentityDatabase;
@class FRAMechanism;

/*!
 * Models a notification in the Authenticator Application. This notification 
 * currently could be assiged to any Mechanism.
 *
 * Node: In practice this will currently just be Push Notifications, but 
 * we imagine other kinds of notifications might be useful later on.
 */
@interface FRANotification : FRAModelObject

/*!
 * Each Notification must be associated with a parent Mechanism.
 */
@property (nonatomic, weak) FRAMechanism *parent;

/*!
 * A timestamp of when the Notification was received by the application.
 */
@property (nonatomic, readonly) NSDate* timeReceived;

/*!
 * The timestamp of when the Notification is expected to expire.
 */
@property (nonatomic) NSDate* timeExpired;

/*!
 * Indicator of whether this Notification is pending. In the pending state a
 * Notification can either be marked as approved or denied. Once it has been
 * either approved or denied, it will move to the non-pending state.
 */
@property (getter=isPending, nonatomic, readonly) BOOL pending;

/*!
 * Indicator of whether the Notification has been approved. Once in the approved
 * state, the Notification is complete and no further action is required.
 */
@property (getter=isApproved, nonatomic, readonly) BOOL approved;

/*!
 * Message Id of the message.
 */
@property (nonatomic, readonly) NSString* messageId;

/*!
 * The push challenge.
 */
@property (nonatomic, readonly) NSString* challenge;

/*!
 * The time to live of the push login window.
 */
@property (nonatomic, readonly) NSTimeInterval* ttl;

/*!
 * Constructor for creating a Nofification.
 */
- (instancetype) initWithDatabase:(FRAIdentityDatabase *)database messageId:(NSString*)messageId challange:(NSString*)challenge timeRecieved:(NSDate*)timeRecieved ttl:(NSTimeInterval*)ttl;

- (instancetype) __unavailable initWithDatabase:(FRAIdentityDatabase *)database;

/*!
 * Generates description of the age of this notification as:
 *
 * @code
 * if (timeReceived < 60 seconds ago)
 *     return "n seconds ago";
 * else if (timeReceived < 60 minutes ago)
 *     return "n minutes ago";
 * else if (timeReceived < 24 hours ago)
 *     return "n hours ago";
 * else if (timeReceived < 1 day ago)
 *     return "Yesterday";3
 * else if (timeReceived < 7 day ago)
 *     return "n days ago";
 * else
 *     return timeReceived using date format "dd/MM/yyyy";
 */
- (NSString *)age;

/*!
 * Mark the notification as accepted to indicate the user accepts this
 * Notification.
 */
- (void)approve;

/*!
 * Mark the notification as denied to indicate the user has denied the
 * Notification.
 */
- (void)deny;


@end
