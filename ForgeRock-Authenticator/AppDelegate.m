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
 * Portions Copyright 2013 Nathaniel McCallum, Red Hat
 */

#import "AppDelegate.h"
#import "FRAApplicationAssembly.h"
#import "FRAIdentity.h"
#import "FRAIdentityDatabase.h"
#import "FRAIdentityModel.h"
#import "FRAUriMechanismReader.h"
#import "FRANotification.h"
#import "FRANotificationGateway.h"
#import "FRAOathMechanism.h"
#import "FRAPushMechanism.h"


@implementation AppDelegate

#pragma mark -
#pragma mark UIApplicationDelegate - application lifecycle state changes

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"application:willFinishLaunchingWithOptions:%@", launchOptions);
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[[self assembly] notificationGateway] application:application didFinishLaunchingWithOptions:launchOptions];
    [self populateWithDummyData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleIdentityDatabaseChanged:) name:FRAIdentityDatabaseChangedNotification object:nil];
    [self updateNotificationsCount];
    NSLog(@"application:didFinishLaunchingWithOptions\n%@", launchOptions);
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"applicationDidBecomeActive:");
    [[[self assembly] notificationGateway] applicationDidBecomeActive:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"applicationDidEnterBackground:");
    [[[self assembly] notificationGateway] applicationDidEnterBackground:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"applicationWillTerminate:");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark UIApplicationDelegate - handling remote notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"application:didRegisterForRemoteNotificationsWithDeviceToken:");
    [[[self assembly] notificationGateway] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError:");
    [[[self assembly] notificationGateway] application:application didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"application:didReceiveRemoteNotification:");
    [[[self assembly] notificationGateway] application:application didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"application:didReceiveRemoteNotification:fetchCompletionHandler:");
    [[[self assembly] notificationGateway] application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

#pragma mark -
#pragma mark UIApplicationDelegate - opening a URL-specified resource

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"application:openURL:sourceApplication:annotation:");
    // Create mechanism from URL
    FRAUriMechanismReader* factory = [[self assembly] uriMechanismReader];
    FRAMechanism* mechanism = [factory parseFromURL:url];
    if (mechanism == nil) {
        return NO;
    }
    // Reload the view
    [self.window.rootViewController loadView];
    return YES;
}

#pragma mark -
#pragma mark AppDelegate (private)

- (id)initialFactory {
    TyphoonComponentFactory *factory = [[TyphoonBlockComponentFactory alloc] initWithAssembly:[FRAApplicationAssembly assembly]];
    [factory makeDefault];
    return factory;
}

- (FRAApplicationAssembly *)assembly {
    return (FRAApplicationAssembly *) [TyphoonComponentFactory defaultFactory];
}

- (void)populateWithDummyData {
    FRAUriMechanismReader *factory = [[self assembly] uriMechanismReader];
    FRAIdentityDatabase *database = [[self assembly] identityDatabase];
    
    [factory parseFromURL:[NSURL URLWithString:@"otpauth://totp/Umbrella-Corp:Alice?secret=ZIFYT2GJ5UDGYCBYJ777PFBPSM======&issuer=Umbrella-Corp&digits=6&period=30"]];
    
    [factory parseFromURL:[NSURL URLWithString:@"otpauth://hotp/Umbrella-Corp:Adam?secret=IJQWIZ3FOIQUEYLE&issuer=Umbrella-Corp&counter=0"]];
    
    FRAIdentity *demo = [FRAIdentity identityWithDatabase:database accountName:@"demo" issuer:@"ForgeRock" image:nil backgroundColor:nil];
    FRAPushMechanism *pushMechanism = [[FRAPushMechanism alloc] initWithDatabase:database];

    // TODO: Handle Error
    @autoreleasepool {
        NSError* error;
        [demo addMechanism:pushMechanism error:&error];
    }
    
    NSTimeInterval timeToLive = 120.0;
    FRANotification *approvedNotification = [[FRANotification alloc] initWithDatabase:database
                                                                            messageId:@"messageId"
                                                                            challenge:[@"challenge" dataUsingEncoding:NSUTF8StringEncoding]
                                                                         timeReceived:[NSDate dateWithTimeIntervalSinceNow:-360.0]
                                                                           timeToLive:timeToLive];
    // TODO: Handle Error
    @autoreleasepool {
        NSError* error;
        [approvedNotification approveWithError:&error];
    }
    FRANotification *deniedNotification = [[FRANotification alloc] initWithDatabase:database
                                                                          messageId:@"messageId"
                                                                          challenge:[@"challenge" dataUsingEncoding:NSUTF8StringEncoding]
                                                                       timeReceived:[NSDate dateWithTimeIntervalSinceNow:-3060.0]
                                                                                timeToLive:timeToLive];
    // TODO: Handle Error
    @autoreleasepool {
        NSError* error;
        [deniedNotification denyWithError:&error];
    }
    FRANotification *pendingNotification = [[FRANotification alloc] initWithDatabase:database
                                                                           messageId:@"messageId"
                                                                           challenge:[@"challenge" dataUsingEncoding:NSUTF8StringEncoding]
                                                                        timeReceived:[NSDate date]
                                                                          timeToLive:timeToLive];

    FRANotification *expiringNotification = [[FRANotification alloc] initWithDatabase:database
                                                                            messageId:@"messageId"
                                                                            challenge:[@"challenge" dataUsingEncoding:NSUTF8StringEncoding]
                                                                         timeReceived:[NSDate date]
                                                                           timeToLive:10.0];
    // TODO: Handle Error
    @autoreleasepool {
        NSError* error;
        [pushMechanism addNotification:approvedNotification error:&error];
    }

    // TODO: Handle Error
    @autoreleasepool {
        NSError* error;
        [pushMechanism addNotification:deniedNotification error:&error];
    }
    
    // TODO: Handle Error
    @autoreleasepool {
        NSError* error;
        [pushMechanism addNotification:pendingNotification error:&error];
    }

    // TODO: Handle Error
    @autoreleasepool {
        NSError* error;
        [pushMechanism addNotification:expiringNotification error:&error];
    }
    
    // TODO: Handle Error
    @autoreleasepool {
        NSError* error;
        [[[self assembly] identityModel] addIdentity:demo error:&error];
    }

    NSLog(@"registered push mechanism with uid: %ld", (long)pushMechanism.uid);
}

- (void)handleIdentityDatabaseChanged:(NSNotification *)notification {
    NSLog(@"database changed: %@", notification.userInfo);
    [self updateNotificationsCount];
}

- (void)updateNotificationsCount {
    [UIApplication sharedApplication].applicationIconBadgeNumber = [[[self assembly] identityModel] pendingNotificationsCount];
}

@end
