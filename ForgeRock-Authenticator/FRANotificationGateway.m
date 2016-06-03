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

#import "FRANotificationGateway.h"

/*!
 * Private interface.
 */
@interface FRANotificationGateway ()

/*! The object to which push notifications received by this object will be passed. */
@property (nonatomic, strong, readonly) FRANotificationHandler *notificationHandler;

@end

@implementation FRANotificationGateway

#pragma mark -
#pragma mark Lifecycle

- (instancetype)initWithHandler:(FRANotificationHandler *)handler {
    self = [super init];
    if (self) {
        _notificationHandler = handler;
    }
    return self;
}

+ (instancetype)gatewayWithHandler:(FRANotificationHandler *)handler {
    return [[FRANotificationGateway alloc] initWithHandler:handler];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Register for remote notifications from APNS
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        // iOS 7.1 or earlier
        UIRemoteNotificationType allNotificationTypes = (UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge);
        [application registerForRemoteNotificationTypes:allNotificationTypes];
    } else {
        // iOS 8 or later
        UIUserNotificationType allNotificationTypes = (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }

    return YES;
}

#pragma mark -
#pragma mark Remote Notifications

// XXX: Also need to implement method to see what notification types have been permitted and respond accordingly
//      e.g. show a warning to user if notifications disabled and a push authn mechanism has been registered
//      or show a warning when attempting to register a push authn mechanism

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"Registered for remote notifications. deviceToken=%@", deviceToken);
    _deviceToken = [self stringFromDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Registration for remote notification failed with error: %@", error.localizedDescription);
    _deviceToken = nil;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Notification received: %@", userInfo);
    [[self notificationHandler] application:application didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"Notification received: %@", userInfo);
    [[self notificationHandler] application:application didReceiveRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

#pragma mark -
#pragma mark Private

- (NSString *)stringFromDeviceToken:(NSData *)deviceToken {
    return [[[[deviceToken description]
              stringByReplacingOccurrencesOfString:@"<" withString:@""]
             stringByReplacingOccurrencesOfString:@">" withString:@""]
            stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
