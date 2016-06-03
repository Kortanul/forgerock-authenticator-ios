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


#import "FRANotificationHandler.h"

/*!
 * Gateway which encapsulates interaction with Push Notification Service.
 */
@interface FRANotificationGateway : NSObject

/*! APNS identifier for this app/device pair. This identifier can change when reconnecting to APNS. */
@property (nonatomic, strong, readonly) NSString *deviceToken;

/*!
 * Init method.
 *
 * @param handler The object to which push notifications received by this object will be passed.
 * @return The notification gateway or nil if initialization failed.
 */
- (instancetype)initWithHandler:(FRANotificationHandler *)handler;
/*!
 * Static factory.
 *
 * @param handler The object to which push notifications received by this object will be passed.
 * @return The notification gateway or nil if initialization failed.
 */
+ (instancetype)gatewayWithHandler:(FRANotificationHandler *)handler;
/*!
 * Method copied from UIApplicationDelegate protocol.
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

/*!
 * Method copied from UIApplicationDelegate protocol.
 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
/*!
 * Method copied from UIApplicationDelegate protocol.
 */
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
/*!
 * Method copied from UIApplicationDelegate protocol.
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
/*!
 * Method copied from UIApplicationDelegate protocol.
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;

@end
