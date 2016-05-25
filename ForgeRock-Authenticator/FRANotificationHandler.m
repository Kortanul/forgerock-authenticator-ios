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

#import "FRABlockAlertView.h"
#import "FRAIdentity.h"
#import "FRAIdentityModel.h"
#import "FRAPushMechanism.h"
#import "FRANotification.h"
#import "FRANotificationHandler.h"
#import "FRANotificationViewController.h"
#import "FRAMessageUtils.h"
#import <JWT.h>

/*!
 * Private interface.
 */
@interface FRANotificationHandler ()

/*!
 * The identity model.
 */
@property (nonatomic, strong, readonly) FRAIdentityModel *identityModel;

/*!
 * The database to which notifications should be persisted.
 */
@property (strong, nonatomic) FRAIdentityDatabase *database;

@end

@implementation FRANotificationHandler

static NSString * const TTL_KEY = @"t";
static NSString * const MESSAGE_ID_KEY_PATH = @"aps.messageId";
static NSString * const CHALLENGE_KEY = @"c";
static NSString * const MECHANISM_UID_KEY = @"u";

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel {
    self = [super init];
    if (self) {
        _database = database;
        _identityModel = identityModel;
    }
    return self;
}

+ (instancetype)handlerWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel {
    return [[FRANotificationHandler alloc] initWithDatabase:database identityModel:identityModel];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)messageData {

    FRANotification *notification = [self notificationFromRemoteNotification:messageData];
    
    if (!notification || !notification.pending) {
        // if the notification is nil then there was a problem looking up the mechanism
        // if the notification is not pending, then the notification timed out or was dealt with by opening the app
        // from the homescreen and navigating to the notification; either way, there's nothing further to do here
        return;
    }
    
    [self showNotification:notification ifForegroundApplication:application];
}

- (FRANotification *)notificationFromRemoteNotification:(NSDictionary *)messageData {

    // Decode JWT from modessage
    NSString* alertJwt = [messageData valueForKeyPath:@"aps.alert"];
    
    NSDictionary *payload = [FRAMessageUtils extractJTWBodyFromString:alertJwt];
    
    // makec mechanism from data
    
    NSLog(@"message data: %@", payload);

    // Lookup push mechanism to which the notification should be added
    
    FRAPushMechanism *mechanism = [self pushMechanismTargetForRemoteNotification:payload];
    if (!mechanism) {
        return nil;
    }

    // Try to look up an existing notification (in case this message has already been handled)
    FRANotification *notification = [mechanism notificationWithMessageId:[messageData valueForKeyPath:MESSAGE_ID_KEY_PATH]];
    if (notification) {
        return notification;
    }
    
    // otherwise, create the notification from the message and add it to the mechanism
    
    NSTimeInterval timeToLive = [[payload objectForKey:TTL_KEY] doubleValue];
    notification = [[FRANotification alloc] initWithDatabase:self.database
                                                   messageId:[messageData valueForKeyPath:MESSAGE_ID_KEY_PATH]
                                                   challenge:[payload objectForKey:CHALLENGE_KEY]
                                                timeReceived:[NSDate date]
                                                  timeToLive:timeToLive];
    // TODO: Handle error
    @autoreleasepool {
        NSError* error;
        [mechanism addNotification:notification error:&error];
    }

    return notification;
}

- (FRAPushMechanism *)pushMechanismTargetForRemoteNotification:(NSDictionary *)messageData {
    NSString *mechanismId = [messageData objectForKey:MECHANISM_UID_KEY];
    FRAMechanism *mechanism = [self.identityModel mechanismWithId:mechanismId];
    if ([mechanism isKindOfClass:[FRAPushMechanism class]]) {
        return (FRAPushMechanism *)mechanism;
    } else {
        return nil;
    }
}

- (void)showNotification:(FRANotification *)notification ifForegroundApplication:(UIApplication *)application {
    
    // jump to the notification if the app was in the foreground when the notification arrived or has
    // been opened by clicking on the notification
    
    void (^showNotification)() = ^{
        UIViewController *rootViewController = application.delegate.window.rootViewController;
        UIStoryboard *storyboard = rootViewController.storyboard;
        FRANotificationViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:FRANotificationViewControllerStoryboardIdentifer];
        viewController.notification = notification;
        [rootViewController presentViewController:viewController animated:YES completion:NULL];
    };
    
    switch (application.applicationState) {
            
        case UIApplicationStateBackground: {
            // don't show notification if app is running in background
        }
        break;
            
        case UIApplicationStateActive: {
            // the notification arrived while the app was in the foreground
            
            FRABlockAlertView *alertView = [[FRABlockAlertView alloc] initWithTitle:@"Authentication Request Received"
                                                                            message:nil
                                                                           delegate:nil
                                                                  cancelButtonTitle:nil
                                                                  otherButtonTitles:@"OK", nil];
            alertView.callback = ^(NSInteger offset) {
                const NSInteger okButton = 0;
                if (offset == okButton) {
                    showNotification();
                }
            };
            [alertView show];
        }
        break;
            
        case UIApplicationStateInactive: {
            // the application is being opened from the notification
            showNotification();
        }
        break;
    }
}

@end
