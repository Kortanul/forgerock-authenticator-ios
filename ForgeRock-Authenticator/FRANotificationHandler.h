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

@class FRAIdentityDatabase;
@class FRAIdentityModel;

/*!
 * Consumer for notifications received by FRANotificationGateway.
 *
 * This handler creates FRANotification objects from the data payload of a push notification and persists them to the
 * appropriate FRAPushMechanism in the FRAIdentityModel.
 */
@interface FRANotificationHandler : NSObject

#pragma mark -
#pragma mark Lifecycle

/*!
 * Init method.
 *
 * @param database The database to which this object can be persisted.
 * @param identityModel The identity model to which FRANotification objects will be persisted.
 * @return The initialized notification handler or nil if initialization failed.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel;

/*!
 * Static factory.
 *
 * @param identityModel The identity model to which FRANotification objects will be persisted.
 * @return The notification handler or nil if initialization failed.
 */
+ (instancetype)handlerWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel;

#pragma mark -
#pragma mark Remote Notifications

/*!
 * Method copied from UIApplicationDelegate protocol.
 *
 * Called by FRANotificationGateway when a push notification is received.
 *
 * This method attempts to build an FRANotification object from the provided userInfo and persists it to the
 * FRAIdentityModel under the appropriate FRAPushMechanism.
 *
 * @param application The application object.
 * @param messageData An object graph representing the push notification message received.
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)messageData;

@end
