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
 *
 * Portions copyright 2015 Google Inc.
 */

#import "FRANotificationGateway.h"

/*!
 * Private interface.
 */
@interface FRANotificationGateway ()

/*! The object to which push notifications received by this object will be passed. */
@property (nonatomic, strong, readonly) FRANotificationHandler *notificationHandler;

/*! GCM registration handler - will be removed when switching to Amazon SNS */
@property (nonatomic, strong) void (^registrationHandler)(NSString *registrationToken, NSError *error);
/*! GCM registration token - will be removed when switching to Amazon SNS */
@property (nonatomic, strong) NSString* registrationToken;
/*! GCM registration options (holds APNS deviceId and prod/dev flag) - will be removed when switching to Amazon SNS */
@property (nonatomic, strong) NSDictionary *registrationOptions;

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
    // Configure the Google context:
    // (parses the GoogleService-Info.plist, and initializes the services that have entries in the file)
    NSError* configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);

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

    // Start GCM service

    GCMConfig *gcmConfig = [GCMConfig defaultConfig];
    [[GCMService sharedInstance] startWithConfig:gcmConfig];

    // Initialize handler for registration token request
    // (gets used in application:didRegisterForRemoteNotificationsWithDeviceToken: and onTokenRefresh:)

    __weak typeof(self) weakSelf = self;
    _registrationHandler = ^(NSString *registrationToken, NSError *error){
        if (registrationToken != nil) {
            weakSelf.registrationToken = registrationToken;
            NSLog(@"Registration Token: %@", registrationToken);
        } else {
            NSLog(@"Registration to GCM failed with error: %@", error.localizedDescription);
        }
    };

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {

    // App is transitioning to the foreground, so connect to the GCM cloud service

    [[GCMService sharedInstance] connectWithHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Could not connect to GCM: %@", error.localizedDescription);
        } else {
            NSLog(@"Connected to GCM");
        }
    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {

    // App is transitioning to the background, so disconnect from the GCM cloud service

    [[GCMService sharedInstance] disconnect];
    NSLog(@"Disconnected from GCM");
}

#pragma mark -
#pragma mark Remote Notifications

// XXX: Also need to implement method to see what notification types have been permitted and respond accordingly
//      e.g. show a warning to user if notifications disabled and a push authn mechanism has been registered
//      or show a warning when attempting to register a push authn mechanism

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"Registered for remote notifications. deviceToken=%@", deviceToken);
    _deviceToken = [self stringFromDeviceToken:deviceToken];

    // Successful registration with APNS for notifications; yeilding token: deviceToken
    // Request a GCM registration token so that notifications can be received from GCM

    GGLInstanceIDConfig *instanceIDConfig = [GGLInstanceIDConfig defaultConfig];
    instanceIDConfig.delegate = self;
    [[GGLInstanceID sharedInstance] startWithConfig:instanceIDConfig];
    _registrationOptions = @{
                             kGGLInstanceIDRegisterAPNSOption:deviceToken, // The APNS token
                             kGGLInstanceIDAPNSServerTypeSandboxOption:@NO // YES=development, NO=production
                             };

    [self registerGcmSenderId];

}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Registration for remote notification failed with error: %@", error.localizedDescription);
    _deviceToken = nil;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"Notification received: %@", userInfo);
    [[GCMService sharedInstance] appDidReceiveMessage:userInfo]; // acknowledge receipt
    [[self notificationHandler] handleRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"Notification received: %@", userInfo);
    [[GCMService sharedInstance] appDidReceiveMessage:userInfo]; // acknowledge receipt
    [[self notificationHandler] handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
    NSLog(@"Notification action invoked: %@", userInfo);
}

#pragma mark -
#pragma mark Private

- (void)registerGcmSenderId {
    // Register for notifications from Craig's GCM account Sender ID
    [[GGLInstanceID sharedInstance] tokenWithAuthorizedEntity:@"157258874139"
                                                        scope:kGGLInstanceIDScopeGCM
                                                      options:_registrationOptions
                                                      handler:_registrationHandler];
}

- (NSString *)stringFromDeviceToken:(NSData *)deviceToken {
    return [[[[deviceToken description]
              stringByReplacingOccurrencesOfString:@"<" withString:@""]
             stringByReplacingOccurrencesOfString:@">" withString:@""]
            stringByReplacingOccurrencesOfString:@" " withString:@""];
}

#pragma mark -
#pragma mark GGLInstanceIDDelegate

- (void)onTokenRefresh {

    // A rotation of the registration tokens is happening, so the app needs to request a new token.

    NSLog(@"The GCM registration token needs to be changed.");
    [self registerGcmSenderId];
}

@end
