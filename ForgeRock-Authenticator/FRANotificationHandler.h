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

/*!
 * Consumer for notifications received by FRANotificationGateway.
 *
 * This handler creates FRANotification objects from the data payload of a push notification and persists them to the
 * appropriate FRAPushMechanism in the FRAIdentityDatabase.
 */
@interface FRANotificationHandler : NSObject

/*!
 * Init method.
 *
 * @param database The identity database to which FRANotification objects will be persisted.
 * @return The notification handler or nil if initialization failed.
 */
- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database;
/*!
 * Static factory.
 *
 * @param database The identity database to which FRANotification objects will be persisted.
 * @return The notification handler or nil if initialization failed.
 */
+ (instancetype)handlerWithDatabase:(FRAIdentityDatabase *)database;

/*!
 * Called by FRANotificationGateway when a push notification is received.
 *
 * This method attempts to build an FRANotification object from the provided userInfo and persists it to the
 * FRAIdentityDatabase under the appropriate FRAPushMechanism.
 *
 * @param userInfo An object graph representing the push notification message received.
 */
- (void)handleRemoteNotification:(NSDictionary *)userInfo;

@end
