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
@property (nonatomic, readonly) NSDate *timeReceived;

/*!
 * The timestamp of when the Notification is expected to expire.
 */
@property (nonatomic) NSDate *timeExpired;

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
 * Indicator of whether the Notification has been denied. Once in the denied
 * state, the Notification is complete and no further action is required.
 */
@property (getter=isDenied, nonatomic, readonly) BOOL denied;

/*!
 * Indicator of whether the Notification has expired. Once in the expired
 * state, the Notification is complete and no further action is required.
 */
@property (getter=isExpired, nonatomic, readonly) BOOL expired;

/*!
 * Message Id of the message.
 */
@property (nonatomic, readonly) NSString *messageId;

/*!
 * The push challenge.
 */
@property (nonatomic, readonly) NSString *challenge;

/*!
 * The time to live of the push login window.
 */
@property (nonatomic, readonly) NSTimeInterval timeToLive;

/*!
 * The load balancer cooky to send with the notification response.  Format = "<cookiename>=<cookievalue">.
 */
@property (nonatomic, readonly) NSString *loadBalancerCookie;


/*!
 * Constructor for creating a Notification.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel messageId:(NSString *)messageId challenge:(NSString *)challenge timeReceived:(NSDate *)timeReceived timeToLive:(NSTimeInterval)timeToLive loadBalancerCookieData:(NSString *)loadBalancerCookie pending:(BOOL)pendingState approved:(BOOL)approvedState;

/*!
 * Constructor for creating a Notification.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel messageId:(NSString *)messageId challenge:(NSString *)challenge timeReceived:(NSDate *)timeReceived timeToLive:(NSTimeInterval)timeToLive loadBalancerCookieData:(NSString *)loadBalancerCookie;

/*!
 * Static factory for creating a Notification.
 */
+ (instancetype)notificationWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel messageId:(NSString *)messageId challenge:(NSString *)challenge timeReceived:(NSDate *)timeReceived timeToLive:(NSTimeInterval)timeToLive loadBalancerCookieData:(NSString *)loadBalancerCookie pending:(BOOL)pendingState approved:(BOOL)approvedState;

/*!
 * Static factory for creating a Notification.
 */
+ (instancetype)notificationWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel messageId:(NSString *)messageId challenge:(NSString *)challenge timeReceived:(NSDate *)timeReceived timeToLive:(NSTimeInterval)timeToLive loadBalancerCookieData:(NSString *)loadBalancerCookie;


- (instancetype) __unavailable initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel;

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
 *     return "Yesterday";
 * else if (timeReceived < 7 days ago)
 *     return "n days ago";
 * else
 *     return timeReceived using date format "dd/MM/yyyy";
 */
- (NSString *)age;

/*!
 * Mark the notification as accepted to indicate the user accepts this
 * Notification.
 *
 * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 * @return BOOL NO if there was an error approving the Notification, in which case the error value will be populated.
 */
- (BOOL)approveWithError:(NSError *__autoreleasing*)error;

/*!
 * Mark the notification as denied to indicate the user has denied the
 * Notification.
 *
 * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 * @return BOOL NO if there was an error denying the Notification, in which case the error value will be populated.
 */
- (BOOL)denyWithError:(NSError *__autoreleasing*)error;


@end
